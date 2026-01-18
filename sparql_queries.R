library(XML)
library(RCurl)
library(SPARQL)

endpoint <- "http://dayhoff.inf.um.es:55555/blazegraph/namespace/thrombosis/sparql"

run_query <- function(endpoint, query, name){
  cat("\n[INFO] Ejecutando", name, "...\n")
  res <- SPARQL(endpoint, query)
  df <- as.data.frame(res$results)
  
  cat("[INFO]", name, "->", nrow(df), "filas,", ncol(df), "columnas\n")
  print(utils::head(df, 10))
  
  View(df)
  
  return(df)
}

# Número de tripletas
q0_count_triples <- "
SELECT (COUNT(*) AS ?nTriples)
WHERE { ?s ?p ?o }
"

# ===========================
# QUERY 1: Proteinas participantes en GO:0007596
# ===========================
q1 <- "
PREFIX biolink: <https://biolink.github.io/biolink-model/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>

SELECT DISTINCT ?proteinLabel
WHERE {
  VALUES ?process { <http://purl.obolibrary.org/obo/GO_0007596> }
  ?process biolink:has_participant ?protein .
  ?protein rdfs:label ?proteinLabel .
}
ORDER BY ?proteinLabel
"

# ===========================
# QUERY 2: Genes asociados a condiciones
# ===========================
q2 <- "
PREFIX biolink: <https://biolink.github.io/biolink-model/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>

SELECT DISTINCT ?geneLabel ?conditionLabel
WHERE {
  ?gene biolink:gene_associated_with_condition ?condition .
  ?gene rdfs:label ?geneLabel .
  ?condition rdfs:label ?conditionLabel .
}
ORDER BY ?conditionLabel ?geneLabel
"

# ===========================
# QUERY 3: Variantes - gen - condicion
# ===========================
q3 <- "
PREFIX biolink: <https://biolink.github.io/biolink-model/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>

SELECT DISTINCT ?variantLabel ?geneLabel ?conditionLabel
WHERE {
  ?variant biolink:variant_of ?gene .
  ?variant biolink:related_to ?condition .
  ?variant rdfs:label ?variantLabel .
  ?gene rdfs:label ?geneLabel .
  ?condition rdfs:label ?conditionLabel .
}
ORDER BY ?variantLabel
"

# ===========================
# QUERY 4: Farmacos y condiciones tratadas
# ===========================
q4 <- "
PREFIX biolink: <https://biolink.github.io/biolink-model/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>

SELECT DISTINCT ?drugLabel ?conditionLabel
WHERE {
  ?drug biolink:treats ?condition .
  ?drug rdfs:label ?drugLabel .
  ?condition rdfs:label ?conditionLabel .
}
ORDER BY ?drugLabel
"

# ===========================
# QUERY 5: Consulta federada a UniProt
# ===========================
q5 <- "
PREFIX biolink: <https://biolink.github.io/biolink-model/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX up: <http://purl.uniprot.org/core/>

SELECT DISTINCT ?proteinLabel ?mnemonic ?reviewed
WHERE {
  VALUES ?process { <http://purl.obolibrary.org/obo/GO_0007596> }
  ?process biolink:has_participant ?protein .
  ?protein rdfs:label ?proteinLabel .

  SERVICE <https://sparql.uniprot.org/sparql> {
    OPTIONAL { ?protein up:mnemonic ?mnemonic . }
    OPTIONAL { ?protein up:reviewed ?reviewed . }
  }
}
ORDER BY ?mnemonic
"

# ===========================
# EJECUCION
# ===========================
df0 <- run_query(endpoint, q0_count_triples, "query0_count_triples")
df1 <- run_query(endpoint, q1, "query1_go_proteins")
df2 <- run_query(endpoint, q2, "query2_gene_condition")
df3 <- run_query(endpoint, q3, "query3_variant_gene_condition")
df4 <- run_query(endpoint, q4, "query4_drug_condition")
df5 <- run_query(endpoint, q5, "query5_federated_uniprot")
