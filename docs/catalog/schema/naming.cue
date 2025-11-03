// docs/catalog/schema/naming.cue
// id は <source>.<duty[.sub...]> の安定ID
// <source>: nist80053 / nist80061 / saaslens / sre / sysml81346 / itilCSDM / audit / requirements / risk / process / ...
// duty部分は kebab-case で '.' でネスト可

package catalog

#IdRule: =~"^[a-z0-9]+(\\.[a-z0-9-]+)+$"
