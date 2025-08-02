package engine

import (
	"encoding/json"
	"fmt"
	"reflect"
	"strings"
	"time"

	"github.com/diegoholiveira/jsonlogic/v3"
)

// JSONLogicEvaluator implements the AssertionEvaluator interface using JSONLogic
type JSONLogicEvaluator struct {
	config *JSONLogicConfig
}

// JSONLogicConfig holds configuration for JSONLogic evaluation
type JSONLogicConfig struct {
	MaxDepth         int           // Maximum recursion depth for expressions
	Timeout          time.Duration // Timeout for individual expression evaluation
	StrictMode       bool          // Strict mode for type checking
	AllowedOperators []string      // List of allowed JSONLogic operators (empty = all allowed)
	SandboxMode      bool          // Enable sandbox mode for security
}

// DefaultJSONLogicConfig returns a default configuration for JSONLogic evaluation
func DefaultJSONLogicConfig() *JSONLogicConfig {
	return &JSONLogicConfig{
		MaxDepth:         10,
		Timeout:          5 * time.Second,
		StrictMode:       false,
		AllowedOperators: []string{}, // Allow all operators by default
		SandboxMode:      true,
	}
}

// NewJSONLogicEvaluator creates a new JSONLogic evaluator with default configuration
func NewJSONLogicEvaluator() *JSONLogicEvaluator {
	return NewJSONLogicEvaluatorWithConfig(DefaultJSONLogicConfig())
}

// NewJSONLogicEvaluatorWithConfig creates a new JSONLogic evaluator with custom configuration
func NewJSONLogicEvaluatorWithConfig(config *JSONLogicConfig) *JSONLogicEvaluator {
	return &JSONLogicEvaluator{
		config: config,
	}
}

// EvaluateAssertion implements the AssertionEvaluator interface
func (evaluator *JSONLogicEvaluator) EvaluateAssertion(assertion map[string]interface{}, context *EvaluationContext) (*AssertionResult, error) {
	if assertion == nil || len(assertion) == 0 {
		return &AssertionResult{
			Passed:     true,
			Expected:   true,
			Actual:     true,
			Expression: "empty_assertion",
			Message:    "Empty assertion always passes",
		}, nil
	}

	// Build evaluation data from context
	data, err := evaluator.buildEvaluationData(context)
	if err != nil {
		return nil, fmt.Errorf("failed to build evaluation data: %w", err)
	}

	// Validate assertion before evaluation if in strict mode
	if evaluator.config.StrictMode {
		if err := evaluator.ValidateAssertion(assertion); err != nil {
			return nil, fmt.Errorf("assertion validation failed: %w", err)
		}
	}

	// Apply JSONLogic with timeout protection
	result, err := evaluator.applyWithTimeout(assertion, data)
	if err != nil {
		assertionJSON, _ := json.Marshal(assertion)
		return &AssertionResult{
			Passed:     false,
			Expected:   true,
			Actual:     false,
			Expression: string(assertionJSON),
			Message:    fmt.Sprintf("JSONLogic evaluation failed: %v", err),
			Error:      err,
		}, nil
	}

	// Convert result to boolean
	passed := evaluator.convertToBool(result)

	assertionJSON, _ := json.Marshal(assertion)
	return &AssertionResult{
		Passed:     passed,
		Expected:   true,
		Actual:     result,
		Expression: string(assertionJSON),
		Message:    evaluator.buildResultMessage(passed, assertion, result),
	}, nil
}

// ValidateAssertion implements the AssertionEvaluator interface
func (evaluator *JSONLogicEvaluator) ValidateAssertion(assertion map[string]interface{}) error {
	if assertion == nil {
		return fmt.Errorf("assertion cannot be nil")
	}

	// Check for allowed operators if configured
	if len(evaluator.config.AllowedOperators) > 0 {
		if err := evaluator.validateOperators(assertion, evaluator.config.AllowedOperators); err != nil {
			return fmt.Errorf("operator validation failed: %w", err)
		}
	}

	// Check maximum depth
	if err := evaluator.validateDepth(assertion, 0, evaluator.config.MaxDepth); err != nil {
		return fmt.Errorf("depth validation failed: %w", err)
	}

	// Try to marshal to JSON to ensure it's valid
	_, err := json.Marshal(assertion)
	if err != nil {
		return fmt.Errorf("assertion is not valid JSON: %w", err)
	}

	return nil
}

// BuildEvaluationData builds the data context for JSONLogic evaluation (exported for testing)
func (evaluator *JSONLogicEvaluator) BuildEvaluationData(context *EvaluationContext) (map[string]interface{}, error) {
	return evaluator.buildEvaluationData(context)
}

// buildEvaluationData builds the data context for JSONLogic evaluation
func (evaluator *JSONLogicEvaluator) buildEvaluationData(context *EvaluationContext) (map[string]interface{}, error) {
	if context == nil {
		return map[string]interface{}{}, nil
	}

	data := make(map[string]interface{})

	// Add span data if available
	if context.Span != nil {
		span := context.Span
		
		// Span basic information
		data["span"] = map[string]interface{}{
			"id":         span.SpanID,
			"name":       span.Name,
			"trace_id":   span.TraceID,
			"parent_id":  span.ParentID,
			"start_time": span.StartTime,
			"end_time":   span.EndTime,
			"duration":   span.GetDuration(),
			"status": map[string]interface{}{
				"code":    span.Status.Code,
				"message": span.Status.Message,
			},
			"has_error": span.HasError(),
			"is_root":   span.IsRoot(),
		}

		// Add span attributes directly to root level for easier access
		// Replace dots with underscores to avoid JSONLogic property access issues
		for key, value := range span.Attributes {
			// Keep original key for backward compatibility
			data[key] = value
			// Also add with underscores for JSONLogic compatibility
			safeKey := strings.ReplaceAll(key, ".", "_")
			if safeKey != key {
				data[safeKey] = value
			}
		}

		// Add span attributes under "attributes" namespace as well
		data["attributes"] = span.Attributes

		// Add span events
		if len(span.Events) > 0 {
			events := make([]map[string]interface{}, len(span.Events))
			for i, event := range span.Events {
				events[i] = map[string]interface{}{
					"name":       event.Name,
					"timestamp":  event.Timestamp,
					"attributes": event.Attributes,
				}
			}
			data["events"] = events
		}
	}

	// Add trace data if available
	if context.TraceData != nil {
		traceData := context.TraceData
		data["trace"] = map[string]interface{}{
			"id":         traceData.TraceID,
			"span_count": len(traceData.Spans),
		}

		if traceData.RootSpan != nil {
			data["trace"].(map[string]interface{})["root_span"] = map[string]interface{}{
				"id":   traceData.RootSpan.SpanID,
				"name": traceData.RootSpan.Name,
			}
		}
	}

	// Add context variables
	allVars := context.GetAllVariables()
	for key, value := range allVars {
		// Avoid overwriting existing keys, use "vars" namespace
		if _, exists := data[key]; !exists {
			data[key] = value
		}
	}

	// Add variables under "vars" namespace as well
	data["vars"] = allVars

	// Add evaluation metadata
	data["_meta"] = map[string]interface{}{
		"timestamp":    context.Timestamp,
		"evaluator":    "jsonlogic",
		"version":      "1.0",
		"strict_mode":  evaluator.config.StrictMode,
		"sandbox_mode": evaluator.config.SandboxMode,
	}

	return data, nil
}

// applyWithTimeout applies JSONLogic with timeout protection
func (evaluator *JSONLogicEvaluator) applyWithTimeout(rule interface{}, data interface{}) (interface{}, error) {
	if evaluator.config.Timeout <= 0 {
		// No timeout, apply directly
		return jsonlogic.ApplyInterface(rule, data)
	}

	// Use channel to implement timeout
	resultChan := make(chan interface{}, 1)
	errorChan := make(chan error, 1)

	go func() {
		defer func() {
			if r := recover(); r != nil {
				errorChan <- fmt.Errorf("JSONLogic evaluation panicked: %v", r)
			}
		}()

		result, err := jsonlogic.ApplyInterface(rule, data)
		if err != nil {
			errorChan <- err
		} else {
			resultChan <- result
		}
	}()

	select {
	case result := <-resultChan:
		return result, nil
	case err := <-errorChan:
		return nil, err
	case <-time.After(evaluator.config.Timeout):
		return nil, fmt.Errorf("JSONLogic evaluation timed out after %v", evaluator.config.Timeout)
	}
}

// convertToBool converts JSONLogic result to boolean
func (evaluator *JSONLogicEvaluator) convertToBool(result interface{}) bool {
	if result == nil {
		return false
	}

	switch v := result.(type) {
	case bool:
		return v
	case int:
		return v != 0
	case int64:
		return v != 0
	case float64:
		return v != 0.0
	case string:
		return v != ""
	case []interface{}:
		return len(v) > 0
	case map[string]interface{}:
		return len(v) > 0
	default:
		// Use reflection for other types
		rv := reflect.ValueOf(result)
		switch rv.Kind() {
		case reflect.Bool:
			return rv.Bool()
		case reflect.Int, reflect.Int8, reflect.Int16, reflect.Int32, reflect.Int64:
			return rv.Int() != 0
		case reflect.Uint, reflect.Uint8, reflect.Uint16, reflect.Uint32, reflect.Uint64:
			return rv.Uint() != 0
		case reflect.Float32, reflect.Float64:
			return rv.Float() != 0.0
		case reflect.String:
			return rv.String() != ""
		case reflect.Slice, reflect.Array, reflect.Map:
			return rv.Len() > 0
		case reflect.Ptr, reflect.Interface:
			return !rv.IsNil()
		default:
			return true // Non-zero values are truthy
		}
	}
}

// buildResultMessage builds a descriptive message for the assertion result
func (evaluator *JSONLogicEvaluator) buildResultMessage(passed bool, assertion map[string]interface{}, result interface{}) string {
	if passed {
		return fmt.Sprintf("Assertion passed: %v evaluated to %v", assertion, result)
	} else {
		return fmt.Sprintf("Assertion failed: %v evaluated to %v (expected truthy value)", assertion, result)
	}
}

// validateOperators validates that only allowed operators are used
func (evaluator *JSONLogicEvaluator) validateOperators(assertion map[string]interface{}, allowedOps []string) error {
	allowedSet := make(map[string]bool)
	for _, op := range allowedOps {
		allowedSet[op] = true
	}

	return evaluator.validateOperatorsRecursive(assertion, allowedSet)
}

// validateOperatorsRecursive recursively validates operators
func (evaluator *JSONLogicEvaluator) validateOperatorsRecursive(obj interface{}, allowedOps map[string]bool) error {
	switch v := obj.(type) {
	case map[string]interface{}:
		for key, value := range v {
			// Check if key is an operator
			if strings.Contains(key, ".") || len(allowedOps) > 0 {
				if !allowedOps[key] {
					return fmt.Errorf("operator '%s' is not allowed", key)
				}
			}
			
			// Recursively validate nested objects
			if err := evaluator.validateOperatorsRecursive(value, allowedOps); err != nil {
				return err
			}
		}
	case []interface{}:
		for _, item := range v {
			if err := evaluator.validateOperatorsRecursive(item, allowedOps); err != nil {
				return err
			}
		}
	}
	
	return nil
}

// validateDepth validates that the assertion doesn't exceed maximum depth
func (evaluator *JSONLogicEvaluator) validateDepth(obj interface{}, currentDepth, maxDepth int) error {
	if currentDepth > maxDepth {
		return fmt.Errorf("assertion exceeds maximum depth of %d", maxDepth)
	}

	switch v := obj.(type) {
	case map[string]interface{}:
		for _, value := range v {
			if err := evaluator.validateDepth(value, currentDepth+1, maxDepth); err != nil {
				return err
			}
		}
	case []interface{}:
		for _, item := range v {
			if err := evaluator.validateDepth(item, currentDepth+1, maxDepth); err != nil {
				return err
			}
		}
	}

	return nil
}

// GetConfig returns the current configuration
func (evaluator *JSONLogicEvaluator) GetConfig() *JSONLogicConfig {
	return evaluator.config
}

// SetConfig updates the configuration
func (evaluator *JSONLogicEvaluator) SetConfig(config *JSONLogicConfig) {
	evaluator.config = config
}

// ValidateConfig validates the JSONLogic configuration
func ValidateJSONLogicConfig(config *JSONLogicConfig) error {
	if config.MaxDepth <= 0 {
		return fmt.Errorf("MaxDepth must be positive, got %d", config.MaxDepth)
	}

	if config.Timeout < 0 {
		return fmt.Errorf("Timeout cannot be negative, got %s", config.Timeout)
	}

	return nil
}