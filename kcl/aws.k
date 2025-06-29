version = "1.30"

oxr = option("params").oxr
ocds = option("params").ocds

_metadata = lambda name: str, suffix: str, role: str -> any {
    {
        if name != "":
            name = oxr.spec.id + "-" + name
        else:
            name = oxr.spec.id
        annotations = {
            "krm.kcl.dev/composition-resource-name" = suffix
        }
        if role != "":
            labels.role = oxr.spec.id + "-" + role
    }
}

_items = [{
    apiVersion = "eks.aws.upbound.io/v1beta1"
    kind = "Cluster"
    metadata = _metadata("", "ekscluster", "")
    spec.forProvider: {
        region = oxr.spec.parameters.region
        bootstrapSelfManagedAddons = True
        if oxr.spec.parameters.version:
            version = oxr.spec.parameters.version
        else:
            version = version
        roleArnSelector = {
            matchControllerRef = True
            matchLabels.role = oxr.spec.id + "-controlplane"
        }
        vpcConfig = [{
            endpointPrivateAccess = True
            endpointPublicAccess = True
            subnetIdSelector.matchControllerRef = True
        }]
    }
    spec.providerConfigRef = oxr.spec.providerConfigRef
}, {
    apiVersion = "eks.aws.upbound.io/v1beta1"
    kind = "ClusterAuth"
    metadata = _metadata("", "clusterAuth", "")
    spec = {
        forProvider: {
            region = oxr.spec.parameters.region
            clusterNameSelector.matchControllerRef = True
        }
        writeConnectionSecretToRef = {
            name = oxr.spec.id + "-cluster"
            namespace = oxr.spec.claimRef.namespace
        }
        providerConfigRef = oxr.spec.providerConfigRef
    }
}, {
    apiVersion = "eks.aws.upbound.io/v1beta1"
    kind = "NodeGroup"
    metadata = _metadata("", "eksnodegroup", "")
    spec = {
        forProvider = {
            region = oxr.spec.parameters.region
            clusterNameSelector.matchControllerRef = True
            nodeRoleArnSelector = {
                matchControllerRef = True
                matchLabels.role = oxr.spec.id + "-nodegroup"
            }
            subnetIdSelector.matchControllerRef = True
            scalingConfig = [{
                minSize = 1
                maxSize = 10
                desiredSize = 1
                minSize = oxr.spec.parameters.minNodeCount
                desiredSize = oxr.spec.parameters.minNodeCount
            }]
            if oxr.spec.parameters.nodeSize == "small":
                instanceTypes = ["t3.small"]
            elif oxr.spec.parameters.nodeSize == "medium":
                instanceTypes = ["t3.medium"]
            else:
                instanceTypes = ["t3.large"]
        }
        providerConfigRef = oxr.spec.providerConfigRef
    }
}, {
    apiVersion = "ec2.aws.upbound.io/v1beta1"
    kind = "VPC"
    metadata = _metadata("", "vpc-nodepool", "")
    spec = {
        forProvider = {
            region = oxr.spec.parameters.region
            cidrBlock = "10.0.0.0/16"
            enableDnsSupport = True
        }
        providerConfigRef = oxr.spec.providerConfigRef
    }
}, {
    apiVersion: "ec2.aws.upbound.io/v1beta1"
    kind: "SecurityGroup"
    metadata = _metadata("", "sg-nodepool", "")
    spec.forProvider: {
        name = oxr.spec.id
        description = "Cluster communication with worker nodes"
        region = oxr.spec.parameters.region
        vpcIdSelector.matchControllerRef = True
    }
    spec.providerConfigRef = oxr.spec.providerConfigRef
}, {
    apiVersion = "ec2.aws.upbound.io/v1beta1"
    kind = "SecurityGroupRule"
    metadata = _metadata("", "securityGroupRule", "")
    spec.forProvider: {
        description = "I am too lazy to write descriptions"
        region = oxr.spec.parameters.region
        type = "egress"
        fromPort = 0
        toPort = 0
        protocol = "-1"
        cidrBlocks = ["0.0.0.0/0"]
        securityGroupIdSelector.matchControllerRef = True
    }
    spec.providerConfigRef = oxr.spec.providerConfigRef
}, {
    apiVersion = "ec2.aws.upbound.io/v1beta1"
    kind = "InternetGateway"
    metadata = _metadata("", "gateway", "")
    spec.forProvider = {
        region = oxr.spec.parameters.region
        vpcIdSelector.matchControllerRef = True
    }
    spec.providerConfigRef = oxr.spec.providerConfigRef
}, {
    apiVersion = "ec2.aws.upbound.io/v1beta1"
    kind = "RouteTable"
    metadata = _metadata("", "routeTable", "")
    spec.forProvider: {
        region = oxr.spec.parameters.region
        vpcIdSelector.matchControllerRef = True
    }
    spec.providerConfigRef = oxr.spec.providerConfigRef
}, {
    apiVersion: "ec2.aws.upbound.io/v1beta1"
    kind: "Route"
    metadata = _metadata("", "route", "")
    spec.forProvider: {
        region = oxr.spec.parameters.region
        routeTableIdSelector.matchControllerRef = True
        destinationCidrBlock = "0.0.0.0/0"
        gatewayIdSelector.matchControllerRef = True
    }
    spec.providerConfigRef = oxr.spec.providerConfigRef
}, {
    apiVersion: "ec2.aws.upbound.io/v1beta1"
    kind: "MainRouteTableAssociation"
    metadata = _metadata("", "mainRouteTableAssociation", "")
    spec.forProvider: {
        region = oxr.spec.parameters.region
        routeTableIdSelector.matchControllerRef = True
        vpcIdSelector.matchControllerRef = True
    }
    spec.providerConfigRef = oxr.spec.providerConfigRef
}, {
    apiVersion = "eks.aws.upbound.io/v1beta1"
    kind = "Addon"
    metadata = _metadata("ebs", "addonEbs", "")
    spec.forProvider = {
        addonName = "aws-ebs-csi-driver"
        region = oxr.spec.parameters.region
        clusterNameSelector.matchControllerRef = True
    }
    spec.providerConfigRef = oxr.spec.providerConfigRef
}, {
    **oxr
    status.clusterName = oxr.spec.id
    if oxr.spec.id + "-cluster" in ocds:
        status.controlPlaneStatus = ocds[oxr.spec.id + "-cluster"].Resource.status.conditions[0].reason
    if oxr.spec.id + "-node-group" in ocds:
        status.nodePoolStatus = ocds[oxr.spec.id + "-node-group"].Resource.status.conditions[0].reason
}]

_zones = oxr.spec.parameters.vpcConfig.zones

_items += [{
    apiVersion = "ec2.aws.upbound.io/v1beta1"
    kind = "RouteTableAssociation"
    metadata = _metadata(_zone.name, "routeTableAssociation" + _zone.name, "")
    spec.forProvider: {
        region = oxr.spec.parameters.region
        routeTableIdSelector.matchControllerRef = True
        subnetIdSelector = {
            matchControllerRef = True
            matchLabels = {
                zone = _zone.name
                access = "public"
            }
        }
    }
    spec.providerConfigRef = oxr.spec.providerConfigRef
} for _zone in _zones]

_items += [{
    apiVersion = "ec2.aws.upbound.io/v1beta1"
    kind = "Subnet"
    metadata = {
        name = oxr.spec.id + "-" + _zone.name
        annotations = {
            "krm.kcl.dev/composition-resource-name" = "subnet-nodepool-" + _zone.name
        }
        labels = {
            zone = _zone.name
            access: "public"
        }
    }
    spec: {
        forProvider = {
            region = oxr.spec.parameters.region
            availabilityZone = _zone.name
            cidrBlock = _zone.cidr
            vpcIdSelector.matchControllerRef = True
            mapPublicIpOnLaunch = True
            tags = {
                "kubernetes.io/role/elb": "1"
            }
        }
        providerConfigRef = oxr.spec.providerConfigRef
    }
} for _zone in _zones]

_rpas = [
    {name = "controlplane", role = "controlplane", policyArn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"}
    {name = "service", role = "controlplane", policyArn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"}
    {name = "worker", role = "nodegroup", policyArn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"}
    {name = "cni", role = "nodegroup", policyArn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"}
    {name = "registry", role = "nodegroup", policyArn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"}
]

_items += [{
    apiVersion = "iam.aws.upbound.io/v1beta1"
    kind = "RolePolicyAttachment"
    metadata = _metadata(_rpa.name, "iamattachment-" + _rpa.name, "")
    spec = {
        forProvider = {
            policyArn = _rpa.policyArn
            roleSelector = {
                matchControllerRef = True
                matchLabels.role = oxr.spec.id + "-" + _rpa.role
            }
        }
        providerConfigRef = oxr.spec.providerConfigRef
    }
} for _rpa in _rpas]

_roles = [
    {name = "controlplane", service = "eks"}
    {name = "nodegroup", service = "ec2"}
]

_items += [{
    apiVersion = "iam.aws.upbound.io/v1beta1"
    kind = "Role"
    metadata = {
        name = oxr.spec.id + "-" + _role.name
        annotations = {
            "krm.kcl.dev/composition-resource-name" = "iamrole-" + _role.name
        }
        labels.role = oxr.spec.id + "-" + _role.name
    }
    spec.providerConfigRef = oxr.spec.providerConfigRef
    spec.forProvider.assumeRolePolicy = """\
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"Service": [\"""" + _role.service + """.amazonaws.com"]},
    "Action": ["sts:AssumeRole"]
  }]
}
"""
} for _role in _roles]

items = _items
