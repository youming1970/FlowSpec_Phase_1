package parser

import (
	"github.com/flowspec/flowspec-cli/internal/models"
)

// GoFileParser implements FileParser for Go source files
type GoFileParser struct {
	*BaseFileParser
}

// NewGoFileParser creates a new Go file parser
func NewGoFileParser() *GoFileParser {
	return &GoFileParser{
		BaseFileParser: NewBaseFileParser(LanguageGo),
	}
}

// CanParse checks if this parser can handle the given file
func (gp *GoFileParser) CanParse(filename string) bool {
	return gp.BaseFileParser.CanParse(filename)
}

// ParseFile parses a Go file and extracts ServiceSpec annotations
func (gp *GoFileParser) ParseFile(filepath string) ([]models.ServiceSpec, []models.ParseError) {
	return gp.BaseFileParser.ParseFile(filepath)
}
