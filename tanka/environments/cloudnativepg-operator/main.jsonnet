local weebcluster = import 'weebcluster.libsonnet';

local envName = 'cnpgOperator';
local namespace = 'cnpg-system';

// This is honestly kinda stupid, but I hate maintaining helm charts that don't align with the app version.
// I diff'd with a directly applied install and there were no differences, so should be fine.

local cnpgOperatorEnv = std.parseYaml(importstr 'cnpg-operator/cnpg-1.27.0.yaml');

weebcluster.newTankaEnv(envName, namespace, cnpgOperatorEnv)