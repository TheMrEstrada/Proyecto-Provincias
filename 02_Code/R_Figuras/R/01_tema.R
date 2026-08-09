# ============================================================================
# 01_tema.R  —  Plantilla única de estilo para las figuras del diagnóstico
# ============================================================================
tema <- list(
  # Paleta ESTÁNDAR (única permitida): 3 azules + gris. Negro/blanco solo en
  # casos específicos (etiquetas sobre barra, contornos con relleno blanco).
  # Ningún gráfico puede llevar elementos en otros colores.
  navy  = "1F3864",   # serie principal / Hombres / Urbana
  blue  = "4472C4",   # serie secundaria / Rural
  light = "9DC3E6",   # serie terciaria / Mujeres (pirámide)
  gris  = "7F7F7F",   # gris estándar (agregado Departamento, apoyos)
  negro = "000000",
  blanco = "FFFFFF",
  # azules intermedios (dentro del rango de la paleta) para figuras de 5-6 series:
  azul_profundo = "2E5496",   # entre navy (#1F3864) y blue (#4472C4)
  azul_medio    = "6FA8DC",   # entre blue (#4472C4) y light (#9DC3E6)
  # paleta categórica base (4 colores permitidos).
  serie = c("1F3864","4472C4","9DC3E6","7F7F7F"),
  # rampa extendida de 6 (3 azules del proyecto + 2 azules intermedios + gris),
  # ordenada por tono, para figuras con hasta 6 series (p. ej. composición pecuaria).
  serie6 = c("1F3864","2E5496","4472C4","6FA8DC","9DC3E6","7F7F7F"),
  # Marcador estándar para series de puntos (MDM/IDF, radar, scatter, dumbbell):
  # diamante (Excel "Built-In Type 2") tamaño 15. El color se define por figura
  # (contorno = color de serie; relleno = blanco o color según spec).
  marker_symbol = "diamond",
  marker_size   = 15,
  # Tipografía
  fuente      = "Cambria",
  size_titulo = 12,
  size_eje    = 10,
  size_lbl    = 9
)
