// Package schema defines naming conventions for slot IDs
package schema

// #NamingRules defines the stable ID format for slots
// Format: <source>.<duty[.sub...]>
//
// <source> is one of the recognized standard sources:
//   - nist80053: NIST SP 800-53 security controls
//   - nist80061: NIST SP 800-61 incident response
//   - saaslens: AWS SaaS Lens best practices
//   - sre: Site Reliability Engineering practices
//   - sysml81346: ISO/IEC 81346 system modeling
//   - itilCSDM: ITIL Configuration and Service Desk Management
//   - audit: Audit and compliance tracking
//   - requirements: Functional and non-functional requirements
//   - risk: Security, privacy, and compliance risks
//   - process: Development, change, and operational processes
//   - custom: Custom internal responsibilities
//
// <duty[.sub...]> is a hierarchical path describing the specific duty
// Examples:
//   - nist80053.AC-access-control
//   - sre.slo-definition.availability
//   - custom.video.encoding
#NamingRules: {
	// Valid source prefixes
	validSources: [
		"nist80053",
		"nist80061",
		"saaslens",
		"sre",
		"sysml81346",
		"itilCSDM",
		"audit",
		"requirements",
		"risk",
		"process",
		"custom",
	]

	// ID must match the pattern
	idPattern: "^[a-z0-9]+\\.[a-zA-Z0-9_-]+(\\.[a-zA-Z0-9_-]+)*$"
}
