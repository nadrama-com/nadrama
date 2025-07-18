# Nadrama.com Helm Charts

This repository contains [Helm](https://helm.sh/) Charts designed to be used on [Nadrama.com](https://nadrama.com) Kubernetes clusters.

## About Nadrama

[Nadrama](https://nadrama.com) is a container platform designed to let you deploy containers, in your cloud account, in minutes. Nadrama runs cluster VMs in your AWS, Google Cloud, or Azure account, VPC, & region of choice. Lower risk, cost, and complexity, without vendor lock-in. Read more about [Nadrama's commitment to Open Source here](https://nadrama.com/opensource).

## Repository Overview

There are 3 types of charts:

1. Core Charts: designed to be pre-installed on Nadrama clusters, installed into namespaces with a `system-` prefix, managed by Nadrama, and unable to be edited or uninstalled by users.

2. Addons Charts: designed to be optionally installed on Nadrama clusters after creation, installed into namespaces with a `system-` prefix, managed by Nadrama, unable to be edited by users, installed/uninstalled by users via the Nadrama Console or CLI.

3. Default Charts: designed to be pre-installed on Nadrama clusters, installed into user namespaces (without a `system-` prefix, e.g. `default`), able to be edited/uninstalled by users, and are not managed by Nadrama or via ArgoCD.

Note:

- We maintain a flat repository structure. It makes specific charts easy to find, and makes it easy to avoid duplicate chart names. However, to determine which type a chart is, you must reference the [config.sh](./config.sh) file.

- We use separate charts for CRDs per [Helm Best Practices for CRDs](https://helm.sh/docs/chart_best_practices/custom_resource_definitions/#method-2-separate-charts).

- The `system-` prefix is used to simplify RBAC rules / CEL policies.

- The `cluster` chart should not contain any namespaced resources.

## Usage

Setup a `values.yaml` file:

```
./setup.sh <ingress-hostname>
```

Render all Core and Default charts to the `./_rendered` directory:

```
./render.sh (<single-chart>)
```

Install all (or single-chart of) Core and Default charts into the current kubectl context:

```
./install.sh (<single-chart>)
```

Uninstall all (or single-chart of) Core and Default charts from the current kubectl context:

```
./uninstall.sh (<single-chart>)
```

## Installation options for Validating & Mutating Webhooks

There are runtime dependencies for some charts, for example:

* `trust-manager` requires the `cert-manager` `system-cert-manager-webhook` pod to be running
* `trust-bundles` requires the `trust-manager` `system-trust-manager` pod to be running

In both examples above, it's due to the ValidatingWebhookConfiguration and MutatingWebhookConfigurations created in the `cert-manager` and `trust-manager` charts, which are configured with a failurePolicy of `Fail` (fail closed).

When running `./install.sh` you can specify the env var `FORCE_NO_HOOKS=true`, which will temporarily set the failurePolicy of those webhooks to `Ignore` (fail open). This should permit all charts to install correctly, in a single run. While the `./install.sh` script will attempt to restore the failurePolicy to `Ignore` once complete, there is a risk that this does not happen properly, which is why we have not made this the default behaviour.

## Cluster Design & Assumptions

* We assume Kuberentes is configured with dual-stack IPv4 + IPv6.

  * Pod IPv4 CIDR block is `100.64.0.0/10`, supporting
    up to 4,194,304 IPv4 addresses. RFC 6598 reserves this CIDR block for
    reserved for Carrier-Grade NAT.

  * Pod IPv6 CIDR block is `fd64::/48`.

  * Service IPv4 CIDR block is `198.18.0.0/15`, supporting up to 131,072 IPv4
    addresses.

  * Service IPv6 CIDR block is `fdc6::/108`.

    * Note that kube-apiserver requires a prefix length >= 108.

  * Both IPv4 CIDR blocks are defined as private networks
    <https://en.wikipedia.org/wiki/Reserved_IP_addresses>

  * Both IPv4 CIDR blocks fall within the default set of eBPF-based
    nonMasqueradeCIDRs  <https://docs.cilium.io/en/stable/network/concepts/masquerading/>

  * Both IPv4 CIDR blocks are configured on `kube-controller-manager`.
    The service CIDR blocks are configured on `kube-apiserver`.
    We also configure per-Node CIDR blocks with `/24` prefix length for IPv4, and `/64` prefix length for IPv6.

* We configure Cilium CNI to use Kubernetes IPAM mode.

* CoreDNS runs as a DaemonSet

  * It uses the last service IPv4, `198.19.255.254`

  * It uses the last service IPv6, `fdc6::ffff`

  * The  kubelet is configured to use the above two addresses as clusterDNS.

## License

Nadrama Helm Charts are licensed under the Apache License, Version 2.0.
Copyright 2025 Nadrama Pty Ltd.
See [LICENSE](./LICENSE).
