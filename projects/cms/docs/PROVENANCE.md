# Provenance

This project applies two Hypermodern LLC house-code patterns from Looking Local
under Straylight's commercial license:

1. authoring remains permissive while the transition to visible state is gated
   by one reusable completeness validator;
2. PostgreSQL connections come from a bounded `resource-pool` and each action
   runs inside a transaction with local timeout guardrails.

The implementation, publishing domain, SQL schema, and HTTP contract in this
project are new Straylight work. No Looking Local product code, content,
branding, schema vocabulary, or UI implementation was copied.
