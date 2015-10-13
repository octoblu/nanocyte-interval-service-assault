_      = require 'lodash'
debug  = require('debug')('nanocyte-interval-service-assault:index')
MeshbluConfig = require 'meshblu-config'
MeshbluHttp = require 'meshblu-http'

meshbluHttp = new meshbluHttp
# Take the number of devices to create from environment
# Create X number of meshblu devices
# Setup device permissions
# Subscribe to each devoce
# Message the interval service to create a new Interval or Cron job
# Output difference
