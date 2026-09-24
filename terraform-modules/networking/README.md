# networking (placeholder — roadmap phase 1)

Not used by the POC. Azure auto-provisions a managed VNet for the Container Apps Environment
when no `infrastructure_subnet_id` is given, and PostgreSQL Flexible Server uses public access +
a firewall allow-list.

Roadmap phase 1 ("harden infra") replaces both with a private-networking module here:
a VNet with a delegated `/23` subnet for Container Apps and a separate delegated subnet for
Postgres Flexible Server, connected via VNet integration, with `public_network_access_enabled =
false` everywhere and a private DNS zone for the Postgres FQDN. See
[docs/implementation-guide.md](../../docs/implementation-guide.md#roadmap--production-grade-platform).
