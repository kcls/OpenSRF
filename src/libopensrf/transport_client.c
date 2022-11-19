#include <opensrf/transport_client.h>

transport_client* client_init(const char* domain, 
    int port, const char* username, const char* password) {

    osrfLogInfo(OSRF_LOG_MARK, 
        "TCLIENT client_init domain=%s port=%d username=%s", domain, port, username);

	transport_client* client = safe_malloc(sizeof(transport_client));
    client->primary_domain = strdup(domain);
    client->connections = osrfNewHash();

    // These 2 only get values if this client works for a service.
	client->service = NULL;
	client->service_address = NULL;

    client->username = username ? strdup(username) : NULL;
    client->password = password ? strdup(password) : NULL;

    client->port = port;
    client->primary_connection = NULL;

	client->error = 0;

	return client;
}

static transport_con* client_connect_common(
    transport_client* client, const char* domain) {

    osrfLogInfo(OSRF_LOG_MARK, "TCLIENT Connecting to domain: %s", domain);

    transport_con* con = transport_con_new(domain);

    osrfHashSet(client->connections, (void*) con, (char*) domain);

    return con;
}


static transport_con* get_transport_con(transport_client* client, const char* domain) {
    osrfLogInternal(OSRF_LOG_MARK, "TCLIENT get_transport_con() domain=%s", domain);

    transport_con* con = (transport_con*) osrfHashGet(client->connections, (char*) domain);

    if (con != NULL) { return con; }

    // If we don't have the a connection for the requested domain,
    // it means we're setting up a connection to a remote domain.

    con = client_connect_common(client, domain);

    transport_con_set_address(con, NULL);

    // Connections to remote domains assume the same connection
    // attributes apply.
    transport_con_connect(con, client->port, client->username, client->password);

    return con;
}

int client_connect_as_service(transport_client* client, const char* service) {
    osrfLogInternal(OSRF_LOG_MARK, 
        "TCLIENT client_connect_as_service() service=%s", service);

    growing_buffer* buf = buffer_init(32);

    buffer_fadd(buf, "opensrf:service:%s", service);

    client->service_address = buffer_release(buf);
    client->service = strdup(service);

    transport_con* con = client_connect_common(client, client->primary_domain);

    transport_con_set_address(con, service);

    client->primary_connection = con;

    return transport_con_connect(
        con, client->port, client->username, client->password);
}

int client_connect(transport_client* client) {
    osrfLogInternal(OSRF_LOG_MARK, "TCLIENT client_connect()");

    transport_con* con = client_connect_common(client, client->primary_domain);

    transport_con_set_address(con, NULL);

    client->primary_connection = con;

    return transport_con_connect(
        con, client->port, client->username, client->password);
}

// Disconnect all connections and remove them from the connections hash.
int client_disconnect(transport_client* client) {

    osrfLogDebug(OSRF_LOG_MARK, "TCLIENT Disconnecting all transport connections");

    osrfHashIterator* iter = osrfNewHashIterator(client->connections);

    transport_con* con;

    while( (con = (transport_con*) osrfHashIteratorNext(iter)) ) {
        osrfLogInternal(OSRF_LOG_MARK, "TCLIENT Disconnecting from domain: %s", con->domain);
        transport_con_disconnect(con);
        transport_con_free(con);
    }

    osrfHashIteratorFree(iter);
    osrfHashFree(client->connections);

    client->connections = osrfNewHash();

    return 1;
}

int client_connected( const transport_client* client ) {
	return (client != NULL && client->primary_connection != NULL);
}

static char* get_domain_from_address(const char* address) {
    osrfLogInternal(OSRF_LOG_MARK, 
        "TCLIENT get_domain_from_address() address=%s", address);

    char* addr_copy = strdup(address);
    strtok(addr_copy, ":"); // "opensrf:"
    strtok(NULL, ":"); // "client:"
    char* domain = strtok(NULL, ":");

    if (domain) {
        // About to free addr_copy...
        domain = strdup(domain);
    } else {
        osrfLogError(OSRF_LOG_MARK, "No domain parsed from address: %s", address);
    }

    free(addr_copy);

    return domain;
}

int client_send_message(transport_client* client, transport_message* msg) {
    return client_send_message_to(client, msg, msg->recipient) ;
}

int client_send_message_to(transport_client* client, transport_message* msg, const char* recipient) {
    osrfLogInternal(OSRF_LOG_MARK, "TCLIENT client_send_message()");

	if (client == NULL || client->error) { return -1; }

    const char* receiver = recipient == NULL ? msg->recipient : recipient;

    transport_con* con;

    if (strstr(receiver, "opensrf:client")) {
        // We may be talking to a worker that runs on a remote domain.
        // Find or create a connection to the domain.

        char* domain = get_domain_from_address(receiver);

        if (!domain) { return -1; }

        con = get_transport_con(client, domain);

        if (!con) {
            osrfLogError(
                OSRF_LOG_MARK, "Error creating connection for domain: %s", domain);

            return -1;
        }

    } else {
        con = client->primary_connection;
    }
        
    // The message sender is always our primary connection address,
    // since that's the only address we listen for inbound data on.
	if (msg->sender) { free(msg->sender); }
	msg->sender = strdup(client->primary_connection->address);

    message_prepare_json(msg);

    osrfLogInternal(OSRF_LOG_MARK, 
        "client_send_message() to=%s %s", receiver, msg->msg_json);

    return transport_con_send(con, msg->msg_json, receiver);
}

transport_message* client_recv_stream(transport_client* client, int timeout, const char* stream) {

    osrfLogInternal(OSRF_LOG_MARK, 
        "TCLIENT client_recv_stream() timeout=%d stream=%s", timeout, stream);

    transport_con_msg* con_msg = 
        transport_con_recv(client->primary_connection, timeout, stream);

    if (con_msg == NULL) { return NULL; } // Receive timed out.

	transport_message* msg = new_message_from_json(con_msg->msg_json);

    transport_con_msg_free(con_msg);

    osrfLogInternal(OSRF_LOG_MARK, 
        "client_recv() read response for thread %s", msg->thread);

	return msg;
}

transport_message* client_recv(transport_client* client, int timeout) {

    return client_recv_stream(client, timeout, client->primary_connection->address);
}

transport_message* client_recv_for_service(transport_client* client, int timeout) {

    osrfLogInternal(OSRF_LOG_MARK, "TCLIENT Receiving for service %s", client->service);

    return client_recv_stream(client, timeout, client->service_address);
}

/**
	@brief Free a transport_client, along with all resources it owns.
	@param client Pointer to the transport_client to be freed.
	@return 1 if successful, or 0 if not.  The only error condition is if @a client is NULL.
*/
int client_free( transport_client* client ) {
    osrfLogInternal(OSRF_LOG_MARK, "TCLIENT client_free()");
	if (client == NULL) { return 0; }
	return client_discard( client );
}

/**
	@brief Free a transport_client's resources, but without disconnecting.
	@param client Pointer to the transport_client to be freed.
	@return 1 if successful, or 0 if not.  The only error condition is if @a client is NULL.

	A child process may call this in order to free the resources associated with the parent's
	transport_client, but without disconnecting from Jabber, since disconnecting would
	disconnect the parent as well.
 */
int client_discard( transport_client* client ) {
    osrfLogInternal(OSRF_LOG_MARK, "TCLIENT client_discard()");

	if (client == NULL) { return 0; }

    osrfLogInternal(OSRF_LOG_MARK, 
        "Discarding client on domain %s", client->primary_domain);

	if (client->primary_domain) { free(client->primary_domain); }
	if (client->service) { free(client->service); }
	if (client->service_address) { free(client->service_address); }
    if (client->username) { free(client->username); }
    if (client->password) { free(client->password); }

    // Clean up our connections.
    // We do not disconnect here since they caller may or may
    // not want the socket closed.
    // If disconnect() was just called, the connections hash
    // will be empty.
    osrfHashIterator* iter = osrfNewHashIterator(client->connections);

    transport_con* con;

    while( (con = (transport_con*) osrfHashIteratorNext(iter)) ) {
        osrfLogInternal(OSRF_LOG_MARK, 
            "client_discard() freeing connection for %s", con->domain);
        transport_con_free(con);
    }

    osrfHashIteratorFree(iter);
    osrfHashFree(client->connections);

	free(client);

	return 1;
}

