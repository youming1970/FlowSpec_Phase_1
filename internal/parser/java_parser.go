package parser

import (
	"flowspec-cli/internal/models"
)

// JavaFileParser implements FileParser for Java source files
type JavaFileParser struct {
	*BaseFileParser
}

// NewJavaFileParser creates a new Java file parser
func NewJavaFileParser() *JavaFileParser {
	return &JavaFileParser{
		BaseFileParser: NewBaseFileParser(LanguageJava),
	}
}

// CanParse checks if this parser can handle the given file
func (jp *JavaFileParser) CanParse(filename string) bool {
	return jp.BaseFileParser.CanParse(filename)
}

// ParseFile parses a Java file and extracts ServiceSpec annotations
func (jp *JavaFileParser) ParseFile(filepath string) ([]models.ServiceSpec, []models.ParseError) {
	return jp.BaseFileParser.ParseFile(filepath)
}