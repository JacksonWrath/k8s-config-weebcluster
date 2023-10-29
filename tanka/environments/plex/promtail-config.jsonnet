local private = import 'libsonnet-secrets/rewt.libsonnet';

{
  local plexLogsPathPrefix = '/config/plex-volume/Library/Application Support/Plex Media Server/Logs/',
  server: {
    disable: true,
  },
  clients: [
    {url: 'http://%s:%s@gateway.loki/loki/api/v1/push' % 
      [private.loki.gateway_username, private.loki.gateway_password]},
  ],
  scrape_configs: [
    $.scrapeConfigJob(
      jobName='plex-logs',
      pipelineRegex='.*/(?P<filename>.*)',
      plexLogsPathSuffix='*[^.1-9].log'),
    $.scrapeConfigJob(
      jobName='plex-plugin-logs',
      pipelineRegex='.*/(?P<filename>PMS Plugin Logs/.*)',
      plexLogsPathSuffix='PMS Plugin Logs/*.log'),
  ],

  scrapeConfigJob(jobName, pipelineRegex, plexLogsPathSuffix):: {
    job_name: jobName,
    pipeline_stages: [
      $.pipelineStageRegex(pipelineRegex),
      $.pipelineStageLabels(),
    ],
    static_configs: [
      $.staticConfigLabels(jobName, plexLogsPathSuffix)
    ],
  },

  pipelineStageRegex(filenameExpression):: {
    regex: {
      source: 'filename',
      expression: filenameExpression,
    }
  },

  pipelineStageLabels():: {
    labels: {
      filename: '',
    }
  },

  staticConfigLabels(jobName, pathSuffix):: {
    labels: {
      job: jobName,
      app: 'plex',
      __path__: plexLogsPathPrefix + pathSuffix,
    }
  }
}