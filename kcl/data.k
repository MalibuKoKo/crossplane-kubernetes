root = {
    type = "object"
    description = "Parameters used to customize the cluster"
    properties = {
        version = {
            description = "The Kubernetes version for the cluster."
            type = "string"
        }
        vpcConfig = {
            type = "object"
            description = "VPC Config."
            default = {
                region = {
                    name = "eu-west-3"
                    cidr = "10.0.0.0/16"
                }
                zones = [
                    {
                        name = "eu-west-3a"
                        cidr = "10.0.0.0/24"
                    },
                    {
                        name = "eu-west-3b"
                        cidr = "10.0.1.0/24"
                    },
                    {
                        name = "eu-west-3c"
                        cidr = "10.0.2.0/24"
                    }
                ]
            }
            properties = {
                region = {
                    description = "The region"
                    type = "object"
                    properties = {
                        name = {
                            description = "The name of the region"
                            type = "string"
                        }
                        cidr = {
                            description = "The cidr used for this region"
                            type = "string"
                        }
                    }
                }
                zones = {
                    description = "The availability zones"
                    type = "array"
                    items = {
                        type = "object"
                        properties = {
                            name = {
                                description = "The name of the zone"
                                type = "string"
                            }
                            cidr = {
                                description = "The cidr used for this zone"
                                type = "string"
                            }
                        }
                        required = ["name", "cidr"]
                        additionalProperties = False
                    }
                }
            }
            required = ["region","zones"]
        }
        nodeSize = {
            description = "The size of the nodes; small, medium, large."
            type = "string"
            enum = ["small", "medium", "large"]
            default = "small"
        }
        minNodeCount = {
            description = "The minimum number of nodes."
            type = "integer"
            default = 1
        }
        namespaces = {
            description = "List of Namespaces that should be created in the cluster"
            type = "array"
            itemsType = "string"
            defaultArray = "dev,production"
        }
    }
    required = ["nodeSize","vpcConfig"]
}

usage = {
    description = "Whether Crossplane `Usage` (currently alpha feature) is enabled."
    type = "object"
    properties = {
        enabled = {
            type = "boolean"
            default = False
        }
    }
    required = []
}

appCrossplane = {
    type = "object"
    description = "Install Crossplane"
    properties = {
        enabled = {
            type = "boolean"
            default = False
        }
    }
    required = []
}

appArgocd = {
    type = "object"
    description = "Install Argo CD"
    properties = {
        enabled = {
            type = "boolean"
            default = False
        }
        host = {
            type = "string"
            default = "acme.com"
        }
        repoURL = {
            type = "string"
            default = "https://github.com/vfarcic/SOMETHING"
        }
        destinationNamespace = {
            type = "string"
            default = "argo-cd"
        }
        sourcePath = {
            type = "string"
            default = "."
        }
    }
    required = []
}

appOpenfunction = {
    type = "object"
    description = "Install OpenFunction"
    properties = {
        enabled = {
            type = "boolean"
            default = False
        }
    }
    required = []
}

appDapr = {
    type = "object"
    description = "Install Dapr. Do not enable it if OpenFunction is enabled since it comes with Dapr."
    properties = {
        enabled = {
            type = "boolean"
            default = False
        }
    }
    required = []
}

appTraefik = {
    type = "object"
    description = "Install Traefik."
    properties = {
        enabled = {
            type = "boolean"
            default = False
        }
    }
    required = []
}


appExternalSecrets = {
    type = "object"
    description = "Install External Secrets Operator (ESO)"
    properties = {
        enabled = {
            type = "boolean"
            default = False
        }
        store = {
            type = "boolean"
            description = "Whether to create secret store. If `true`, `creds` field needs to be set as well."
        }
        googleCredentialsKey = {
            type = "string"
            description = "The key with Google credentials in the secret. Works only with clusters in Google Cloud."
        }
        awsAccessKeyIDKey = {
            type = "string"
            default = "accessKeyID"
            description = "The key with Access Key ID in the secret. Works only with clusters in AWS."
        }
        awsSecretAccessKeyKey = {
            type = "string"
            default = "secretAccessKey"
            description = "The key with Secret Access Key in the secret. Works only with clusters in AWS."
        }
        azureVaultUrl = {
            type = "string"
            description = "The URL of Azure Vault. Works only with clusters in Azure."
        }
    }
    required = []
}

appExternalSecretsSecrets = {
    type = "array"
    description = "List of secrets to be created from the secret store. The `store` parameter must be set to `true` for this feature to work."
    properties = {
        fromSecret = {
            type = "string"
            description = "The name or the key of secret in the external secret store"
        }
        toSecret = {
            type = "string"
            description = "The name of the secret"
        }
        toNamespace = {
            type = "string"
            description = "The namespace of the secret"
        }
        type = {
            type = "string"
            description = "The type of the secret"
            default = "Opaque"
        }
    }
    required = ["fromSecret", "toSecret", "toNamespace"]
}

creds = {
    type = "object"
    description = "The secret with hyperscaler credentials."
    properties = {
        name = {
            type = "string"
            description = "The name of the secret"
        }
        namespace = {
            type = "string"
            description = "The namespace of the secret"
            default = "crossplane-system"
        }
        keys = {
            description = "The keys in the secret"
            type = "array"
            itemsType = "string"
        }
    }
    required = ["name", "namespace", "keys"]
}

providerConfigRef = {
    type = "object"
    description = "ProviderConfigReference specifies how the provider that will be used to\ncreate, observe, update, and delete this managed resource should be\nconfigured."
    default = {
        name = "default"
    }
    properties = {
        name = {
            type = "string"
            description = "Name of the referenced object."
        }
        policy = {
            description = "Policies for referencing."
            properties = {
                resolution = {
                    default = "Required"
                    description = "Resolution specifies whether resolution of this reference is required.\nThe default is 'Required', which means the reconcile will fail if the\nreference cannot be resolved. 'Optional' means this reference will be\na no-op if it cannot be resolved."
                    enum = [
                      "Required"
                      "Optional"
                    ]
                    type = "string"
                }
                resolve = {
                    description = "Resolve specifies when this reference should be resolved. The default\nis 'IfNotPresent', which will attempt to resolve the reference only when\nthe corresponding field is not present. Use 'Always' to resolve the\nreference on every reconcile."
                    enum = [
                      "Always"
                      "IfNotPresent"
                    ]
                    type = "string"
                }
            }
            type = "object"
        }
    }
    required = ["name"]
}
