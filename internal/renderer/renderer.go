package renderer

import (
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"flowspec-cli/internal/models"
)

// ReportRenderer defines the interface for rendering alignment reports
type ReportRenderer interface {
	RenderHuman(report *models.AlignmentReport) (string, error)
	RenderJSON(report *models.AlignmentReport) (string, error)
	GetExitCode(report *models.AlignmentReport) int
}

// DefaultReportRenderer implements the ReportRenderer interface
type DefaultReportRenderer struct {
	config *RendererConfig
}

// RendererConfig holds configuration for the report renderer
type RendererConfig struct {
	ShowTimestamps    bool
	ShowPerformance   bool
	ShowDetailedErrors bool
	ColorOutput       bool
}

// DefaultRendererConfig returns a default renderer configuration
func DefaultRendererConfig() *RendererConfig {
	return &RendererConfig{
		ShowTimestamps:    true,
		ShowPerformance:   true,
		ShowDetailedErrors: true,
		ColorOutput:       true,
	}
}

// NewReportRenderer creates a new report renderer with default configuration
func NewReportRenderer() *DefaultReportRenderer {
	return &DefaultReportRenderer{
		config: DefaultRendererConfig(),
	}
}

// NewReportRendererWithConfig creates a new report renderer with custom configuration
func NewReportRendererWithConfig(config *RendererConfig) *DefaultReportRenderer {
	return &DefaultReportRenderer{
		config: config,
	}
}

// RenderHuman implements the ReportRenderer interface
func (r *DefaultReportRenderer) RenderHuman(report *models.AlignmentReport) (string, error) {
	var output strings.Builder
	
	// Header
	output.WriteString("FlowSpec 验证报告\n")
	output.WriteString("==================================================\n\n")
	
	// Summary statistics
	output.WriteString("📊 汇总统计\n")
	output.WriteString(fmt.Sprintf("  总计: %d 个 ServiceSpec\n", report.Summary.Total))
	output.WriteString(fmt.Sprintf("  ✅ 成功: %d 个\n", report.Summary.Success))
	output.WriteString(fmt.Sprintf("  ❌ 失败: %d 个\n", report.Summary.Failed))
	output.WriteString(fmt.Sprintf("  ⏭️  跳过: %d 个\n", report.Summary.Skipped))
	
	if r.config.ShowPerformance && report.PerformanceInfo.SpecsProcessed > 0 {
		output.WriteString(fmt.Sprintf("  ⚡ 处理速度: %.2f specs/秒\n", report.PerformanceInfo.ProcessingRate))
		output.WriteString(fmt.Sprintf("  💾 内存使用: %.2f MB\n", report.PerformanceInfo.MemoryUsageMB))
	}
	
	if r.config.ShowTimestamps {
		executionTime := time.Duration(report.ExecutionTime)
		output.WriteString(fmt.Sprintf("  ⏱️  执行时间: %v\n", executionTime))
	}
	
	output.WriteString("\n🔍 详细结果\n")
	output.WriteString("──────────────────────────────────────────────────\n\n")
	
	// Individual results
	for _, result := range report.Results {
		r.renderResultHuman(&output, result)
		output.WriteString("\n")
	}
	
	// Final summary
	output.WriteString("==================================================\n")
	if report.HasFailures() {
		output.WriteString(fmt.Sprintf("验证结果: ❌ 失败 (%d 个断言失败)\n", report.Summary.FailedAssertions))
	} else {
		output.WriteString("验证结果: ✅ 成功 (所有断言通过)\n")
	}
	
	return output.String(), nil
}

// renderResultHuman renders a single alignment result in human format
func (r *DefaultReportRenderer) renderResultHuman(output *strings.Builder, result models.AlignmentResult) {
	// Status icon and operation ID
	statusIcon := r.getStatusIcon(result.Status)
	output.WriteString(fmt.Sprintf("%s %s (%s)\n", statusIcon, result.SpecOperationID, result.Status))
	
	// Execution time
	if r.config.ShowTimestamps {
		executionTime := time.Duration(result.ExecutionTime)
		output.WriteString(fmt.Sprintf("   执行时间: %v\n", executionTime))
	}
	
	// Matched spans
	if len(result.MatchedSpans) > 0 {
		output.WriteString(fmt.Sprintf("   匹配的 Span: %s\n", strings.Join(result.MatchedSpans, ", ")))
	}
	
	// Assertion summary
	if result.AssertionsTotal > 0 {
		output.WriteString(fmt.Sprintf("   断言统计: %d 总计, %d 通过, %d 失败\n", 
			result.AssertionsTotal, result.AssertionsPassed, result.AssertionsFailed))
	}
	
	// Error message for failed results
	if result.Status == models.StatusFailed && result.ErrorMessage != "" {
		output.WriteString(fmt.Sprintf("   错误信息: %s\n", result.ErrorMessage))
	}
	
	// Detailed validation results
	if r.config.ShowDetailedErrors && len(result.Details) > 0 {
		r.renderValidationDetailsHuman(output, result.Details)
	}
}

// renderValidationDetailsHuman renders validation details in human format
func (r *DefaultReportRenderer) renderValidationDetailsHuman(output *strings.Builder, details []models.ValidationDetail) {
	preconditions := []models.ValidationDetail{}
	postconditions := []models.ValidationDetail{}
	
	for _, detail := range details {
		switch detail.Type {
		case "precondition":
			preconditions = append(preconditions, detail)
		case "postcondition":
			postconditions = append(postconditions, detail)
		}
	}
	
	if len(preconditions) > 0 {
		output.WriteString("   前置条件:\n")
		for _, detail := range preconditions {
			r.renderValidationDetailHuman(output, detail, "     ")
		}
	}
	
	if len(postconditions) > 0 {
		output.WriteString("   后置条件:\n")
		for _, detail := range postconditions {
			r.renderValidationDetailHuman(output, detail, "     ")
		}
	}
}

// renderValidationDetailHuman renders a single validation detail in human format
func (r *DefaultReportRenderer) renderValidationDetailHuman(output *strings.Builder, detail models.ValidationDetail, indent string) {
	icon := "✅"
	if !detail.IsPassed() {
		icon = "❌"
	}
	
	output.WriteString(fmt.Sprintf("%s%s %s\n", indent, icon, detail.Message))
	
	if !detail.IsPassed() && r.config.ShowDetailedErrors {
		output.WriteString(fmt.Sprintf("%s   期望: %v\n", indent, detail.Expected))
		output.WriteString(fmt.Sprintf("%s   实际: %v\n", indent, detail.Actual))
		
		if detail.FailureReason != "" {
			output.WriteString(fmt.Sprintf("%s   失败原因: %s\n", indent, detail.FailureReason))
		}
		
		if len(detail.Suggestions) > 0 {
			output.WriteString(fmt.Sprintf("%s   建议:\n", indent))
			for _, suggestion := range detail.Suggestions {
				output.WriteString(fmt.Sprintf("%s   - %s\n", indent, suggestion))
			}
		}
	}
}

// getStatusIcon returns an icon for the given alignment status
func (r *DefaultReportRenderer) getStatusIcon(status models.AlignmentStatus) string {
	switch status {
	case models.StatusSuccess:
		return "✅"
	case models.StatusFailed:
		return "❌"
	case models.StatusSkipped:
		return "⏭️"
	default:
		return "❓"
	}
}

// RenderJSON implements the ReportRenderer interface
func (r *DefaultReportRenderer) RenderJSON(report *models.AlignmentReport) (string, error) {
	jsonData, err := json.MarshalIndent(report, "", "  ")
	if err != nil {
		return "", fmt.Errorf("failed to marshal report to JSON: %w", err)
	}
	
	return string(jsonData), nil
}

// GetExitCode implements the ReportRenderer interface
func (r *DefaultReportRenderer) GetExitCode(report *models.AlignmentReport) int {
	if report == nil {
		return 2 // System error
	}
	
	if report.HasFailures() {
		return 1 // Validation failures
	}
	
	return 0 // Success
}
