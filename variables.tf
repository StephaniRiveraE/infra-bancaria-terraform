# =============================================================================
# VARIABLES GLOBALES - Ecosistema Bancario
# =============================================================================

variable "common_tags" {
  description = "Tags comunes para todos los recursos"
  type        = map(string)
  default = {
    Environment = "production"
    Project     = "ecosistema-bancario"
    ManagedBy   = "terraform"
  }
}
