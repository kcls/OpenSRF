#include <opensrf/transport_connection.h>

transport_con* transport_con_new(const char* domain) {

    osrfLogInternal(OSRF_LOG_MARK, "TCON transport_con_new() domain=%s", domain);

    transport_con* con = safe_malloc(sizeof(transport_con));

    con->bus = NULL;
    con->address = NULL;
    con->domain = strdup(domain);
    con->max_queue = 1000; // TODO pull from config

    osrfLogInternal(OSRF_LOG_MARK, 
        "TCON created transport connection with domain: %s", con->domain);

    return con;
}

void transport_con_msg_free(transport_con_msg* msg) {
    osrfLogInternal(OSRF_LOG_MARK, "TCON transport_con_msg_free()");

    if (msg == NULL) { return; } 

    if (msg->msg_id) { free(msg->msg_id); }
    if (msg->msg_json) { free(msg->msg_json); }

    free(msg);
}

void transport_con_free(transport_con* con) {
    osrfLogInternal(OSRF_LOG_MARK, "TCON transport_con_free()");

    osrfLogInternal(
        OSRF_LOG_MARK, "Freeing transport connection for %s", con->domain);

    if (con->bus) { free(con->bus); }
    if (con->address) { free(con->address); }
    if (con->domain) { free(con->domain); }

    free(con);
}

int transport_con_connected(transport_con* con) {
    return con->bus != NULL;
} 

void transport_con_set_address(transport_con* con, const char* service) {
    osrfLogInternal(OSRF_LOG_MARK, "TCON transport_con_set_address()");

    char hostname[1024];
    hostname[1023] = '\0';
    gethostname(hostname, 1023);

    growing_buffer *buf = buffer_init(64);
    buffer_fadd(buf, "opensrf:client:%s:%s:", con->domain, hostname);

    if (service != NULL) {
        buffer_fadd(buf, "%s:", service);
    }

    buffer_fadd(buf, "%ld", (long) getpid());

    char junk[256];
    snprintf(junk, sizeof(junk), 
        "%f%d", get_timestamp_millis(), (int) time(NULL));

    char* md5 = md5sum(junk);

    buffer_add(buf, ":");
    buffer_add_n(buf, md5, 8);

    con->address = buffer_release(buf);

    osrfLogDebug(OSRF_LOG_MARK, "Connection set address to %s", con->address);
}

int transport_con_connect(
    transport_con* con, int port, const char* username, const char* password) {
    osrfLogInternal(OSRF_LOG_MARK, "TCON transport_con_connect()");

    osrfLogDebug(OSRF_LOG_MARK, "Transport con connecting with bus "
        "domain=%s; address=%s; port=%d; username=%s", 
        con->domain,
        con->address,
        port, 
        username
    );

    con->bus = redisConnect(con->domain, port);

    if (con->bus == NULL) {
        osrfLogError(OSRF_LOG_MARK, "Could not connect to Redis instance");
        return 0;
    }

    osrfLogDebug(OSRF_LOG_MARK, "Connected to Redis instance OK");

    redisReply *reply = 
        redisCommand(con->bus, "AUTH %s %s", username, password);

    if (handle_redis_error(reply, "AUTH %s %s", username, password)) { 
        return 0; 
    }

    freeReplyObject(reply);

    return transport_con_make_stream(con, con->address, 0);
}

int transport_con_make_stream(transport_con* con, const char* stream, int exists_ok) {
    osrfLogInternal(OSRF_LOG_MARK, "TCON transport_con_make_stream() stream=%s", stream);

    redisReply *reply = redisCommand(
        con->bus, 
        "XGROUP CREATE %s %s $ mkstream", 
        stream,
        stream,
        "$",
        "mkstream"
    );

    // Produces an error when a group/stream already exists, but that's
    // acceptible when creating a group/stream for a stop-level service 
    // address, since multiple Listeners are allowed.
    if (handle_redis_error(reply, 
        "XGROUP CREATE %s %s $ mkstream", 
        stream,
        stream,
        "$",
        "mkstream"
    )) { return exists_ok; }

    freeReplyObject(reply);

    return 1;
}

int transport_con_disconnect(transport_con* con) {
    osrfLogInternal(OSRF_LOG_MARK, "TCON transport_con_disconnect()");

    if (con == NULL || con->bus == NULL) { return -1; }

    redisReply *reply = redisCommand(con->bus, "DEL %s", con->address);

    if (!handle_redis_error(reply, "DEL %s", con->address)) {
        freeReplyObject(reply);
    }

    redisFree(con->bus);
    con->bus = NULL;

    return 0;
}

int transport_con_send(transport_con* con, const char* msg_json, const char* stream) {

    osrfLogInternal(OSRF_LOG_MARK, "Sending to stream=%s: %s", stream, msg_json);

    redisReply *reply = redisCommand(con->bus,
        "XADD %s NOMKSTREAM MAXLEN ~ %d * message %s",
        stream,
        con->max_queue,
        msg_json
    );

    if (handle_redis_error(reply, 
        "XADD %s NOMKSTREAM MAXLEN ~ %d * message %s",
        stream, con->max_queue, msg_json)) {

        return -1;
    }

    freeReplyObject(reply);

    return 0;
}

transport_con_msg* transport_con_recv_once(transport_con* con, int timeout, const char* stream) {
    osrfLogInternal(OSRF_LOG_MARK, 
        "TCON transport_con_recv_once() timeout=%d stream=%s", timeout, stream);

    if (stream == NULL) { stream = con->address; }

    redisReply *reply, *tmp;
    char *msg_id = NULL, *json = NULL;

    if (timeout == 0) {

        reply = redisCommand(con->bus, 
            "XREADGROUP GROUP %s %s COUNT 1 STREAMS %s >",
            stream, con->address, stream
        );

    } else {

        if (timeout == -1) {
            // Redis timeout 0 means block indefinitely
            timeout = 0;
        } else {
            // Milliseconds
            timeout *= 1000;
        }

        reply = redisCommand(con->bus, 
            "XREADGROUP GROUP %s %s BLOCK %d COUNT 1 STREAMS %s >",
            stream, con->address, timeout, stream
        );
    }

    // Timeout or error
    if (handle_redis_error(
        reply,
        "XREADGROUP GROUP %s %s %s COUNT 1 NOACK STREAMS %s >",
        stream, con->address, "BLOCK X", stream
    )) { return NULL; }

    // Unpack the XREADGROUP response, which is a nest of arrays.
    // These arrays are mostly 1 and 2-element lists, since we are 
    // only reading one item on a single stream.
    if (reply->type == REDIS_REPLY_ARRAY && reply->elements > 0) {
        tmp = reply->element[0];

        if (tmp->type == REDIS_REPLY_ARRAY && tmp->elements > 1) {
            tmp = tmp->element[1];

            if (tmp->type == REDIS_REPLY_ARRAY && tmp->elements > 0) {
                tmp = tmp->element[0];

                if (tmp->type == REDIS_REPLY_ARRAY && tmp->elements > 1) {
                    redisReply *r1 = tmp->element[0];
                    redisReply *r2 = tmp->element[1];

                    if (r1->type == REDIS_REPLY_STRING) {
                        msg_id = strdup(r1->str);
                    }

                    if (r2->type == REDIS_REPLY_ARRAY && r2->elements > 1) {
                        // r2->element[0] is the message name, which we
                        // currently don't use for anything.

                        r2 = r2->element[1];

                        if (r2->type == REDIS_REPLY_STRING) {
                            json = strdup(r2->str);
                        }
                    }
                }
            }
        }
    }

    freeReplyObject(reply); // XREADGROUP

    if (msg_id == NULL) {
        // Read timed out. 'json' will also be NULL.
        return NULL;
    }

    transport_con_msg* tcon_msg = safe_malloc(sizeof(transport_con_msg));
    tcon_msg->msg_id = msg_id;
    tcon_msg->msg_json = json;

    osrfLogInternal(OSRF_LOG_MARK, "recv_one_chunk() read json: %s", json);

    return tcon_msg;
}


transport_con_msg* transport_con_recv(transport_con* con, int timeout, const char* stream) {
    osrfLogInternal(OSRF_LOG_MARK, "TCON transport_con_recv() stream=%s", stream);

    if (timeout == 0) {
        return transport_con_recv_once(con, 0, stream);

    } else if (timeout < 0) {
        // Keep trying until we have a result.

        while (1) {
            transport_con_msg* msg = transport_con_recv_once(con, -1, stream);
            if (msg != NULL) { return msg; }
        }
    }

    time_t seconds = (time_t) timeout;

    while (seconds > 0) {
        // Keep trying until we get a response or our timeout is exhausted.

        time_t now = time(NULL);
        transport_con_msg* msg = transport_con_recv_once(con, timeout, stream);

        if (msg == NULL) {
            seconds -= now;
        } else {
            return msg;
        }
    }

    return NULL;
}

void transport_con_flush_socket(transport_con* con) {
}

// Returns false/0 on success, true/1 on failure.
// On error, the reply is freed.
int handle_redis_error(redisReply *reply, const char* command, ...) {
    VA_LIST_TO_STRING(command);

    if (reply != NULL && reply->type != REDIS_REPLY_ERROR) {
        osrfLogInternal(OSRF_LOG_MARK, "Redis Command: %s", VA_BUF);
        return 0;
    }

    char* err = reply == NULL ? "" : reply->str;
    osrfLogError(OSRF_LOG_MARK, "REDIS Error [%s] %s", err, VA_BUF);
    freeReplyObject(reply);

    return 1;
}
