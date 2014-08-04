# encoding: utf-8

module Cql
  class Cluster
    def initialize(logger, io_reactor, control_connection, cluster_registry, execution_options, load_balancing_policy, reconnection_policy, retry_policy, connection_options)
      @logger                = logger
      @io_reactor            = io_reactor
      @control_connection    = control_connection
      @registry              = cluster_registry
      @execution_options     = execution_options
      @load_balancing_policy = load_balancing_policy
      @reconnection_policy   = reconnection_policy
      @retry_policy          = retry_policy
      @connection_options    = connection_options
    end

    def hosts
      @registry.hosts
    end

    def register(listener)
      @registry.add_listener(listener)
      self
    end

    def connect_async(keyspace = nil)
      client  = Client.new(@logger, @registry, @io_reactor, @load_balancing_policy, @reconnection_policy, @retry_policy, @connection_options)
      session = Session.new(client, @execution_options)

      f = client.connect
      f = f.flat_map { session.execute_async("USE #{keyspace}") } if keyspace
      f.map(session)
    end

    def connect(keyspace = nil)
      connect_async(keyspace).get
    end

    def close_async
      @control_connection.close_async.map(self)
    end

    def close
      close_async.get
    end
  end
end

require 'cql/cluster/client'
require 'cql/cluster/control_connection'
require 'cql/cluster/eviction_policy'
require 'cql/cluster/registry'
