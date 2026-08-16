# INFORMAÇÕES GERAIS DA API

## Documentação da API (Swagger)

Com a aplicação rodando localmente, acesse a documentação:

* **Swagger UI:** [http://localhost:8080/swagger-ui.html](http://localhost:8080/swagger-ui.html)
* **OpenAPI Spec (JSON):** [http://localhost:8080/v3/api-docs](http://localhost:8080/v3/api-docs)

**Obs.: Todos os erros retornam o mesmo JSON:**
```json
{
  "status": 400,
  "message": "Um ou mais campos estão com valores inválidos",
  "timestamp": "2026-08-16T18:18:35Z",
  "errors": {
    "email": "E-mail é obrigatório",
    "password": "Senha deve ter no mínimo 6 caracteres"
  }
}

Erros nas regras de negócio não retornam o campo "errors".
```
