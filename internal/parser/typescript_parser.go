package parser

import (
	"flowspec-cli/internal/models"
)

// TypeScriptFileParser implements FileParser for TypeScript source files
type TypeScriptFileParser struct {
	*BaseFileParser
}

// NewTypeScriptFileParser creates a new TypeScript file parser
func NewTypeScriptFileParser() *TypeScriptFileParser {
	return &TypeScriptFileParser{
		BaseFileParser: NewBaseFileParser(LanguageTypeScript),
	}
}

// CanParse checks if this parser can handle the given file
func (tp *TypeScriptFileParser) CanParse(filename string) bool {
	return tp.BaseFileParser.CanParse(filename)
}

// ParseFile parses a TypeScript file and extracts ServiceSpec annotations
func (tp *TypeScriptFileParser) ParseFile(filepath string) ([]models.ServiceSpec, []models.ParseError) {
	return tp.BaseFileParser.ParseFile(filepath)
}