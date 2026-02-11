# Guía de Migración: MongoDB a DynamoDB para `switch-ms-directorio`

## Contexto
La infraestructura actual en AWS para el ecosistema bancario **NO incluye** un cluster de DocumentDB (MongoDB). En su lugar, se ha provisionado una tabla de **DynamoDB** llamada `switch-directorio-instituciones` para el almacenamiento de datos del directorio.

Para que el microservicio `switch-ms-directorio` funcione en el entorno desplegado, es necesario migrar la capa de persistencia de **Spring Data MongoDB** a **Spring Data DynamoDB** (o AWS SDK v2).

## Recursos Existentes
- **Tabla DynamoDB:** `switch-directorio-instituciones`
- **Región:** `us-east-2`
- **Partition Key (Hash Key):** `id` (String)

---

## Pasos para la Migración

### 1. Actualizar `pom.xml`

Eliminar la dependencia de MongoDB y agregar la de DynamoDB. Se recomienda usar la librería `com.github.derjust:spring-data-dynamodb` para mantener una interfaz similar a Spring Data, o usar el AWS SDK v2 directamente.

**Eliminar:**
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-mongodb</artifactId>
</dependency>
```

**Agregar (Opción Spring Data DynamoDB):**
```xml
<dependency>
    <groupId>com.github.derjust</groupId>
    <artifactId>spring-data-dynamodb</artifactId>
    <version>5.1.0</version> <!-- Verificar versión compatible con Spring Boot 3 -->
</dependency>
```

### 2. Configuración (`application.yml`)

Eliminar las propiedades de MongoDB (`spring.data.mongodb.uri`) y configurar el cliente de DynamoDB.

```yaml
amazon:
  dynamodb:
    endpoint: https://dynamodb.us-east-2.amazonaws.com
    region: us-east-2
```

> **Nota:** En producción (EKS), la autenticación debe manejarse automáticamente a través del **IAM Role del Nodo** o **IRSA (IAM Roles for Service Accounts)**. No se deben hardcodear `accessKey` ni `secretKey`.

### 3. Modificar la Entidad (Entity)

Cambiar las anotaciones de Mongo (`@Document`, `@Id`) por las de DynamoDB.

**Antes (MongoDB):**
```java
@Document(collection = "instituciones")
public class Institucion {
    @Id
    private String id;
    private String nombre;
    // ...
}
```

**Después (DynamoDB):**
```java
@DynamoDBTable(tableName = "switch-directorio-instituciones")
public class Institucion {
    
    @Id
    @DynamoDBHashKey(attributeName = "institucion_id") // IMPORTANTE: Coincidir con DynamoDB
    private String id;

    @DynamoDBAttribute
    private String nombre;
    
    // Getters y Setters...
}
```

### 4. Modificar el Repositorio

Si usas Spring Data, el cambio es mínimo. Solo asegúrate de extender `EnableScan` si necesitas búsquedas que no sean por ID (aunque se recomienda evitar scan).

```java
@EnableScan
public interface InstitucionRepository extends CrudRepository<Institucion, String> {
    // Métodos personalizados...
}
```

### 5. Clase de Configuración

Es necesario crear una clase `@Configuration` para habilitar los repositorios de DynamoDB.

```java
@Configuration
@EnableDynamoDBRepositories(basePackages = "com.bancadigital.switch.directorio.repository")
public class DynamoDBConfig {

    @Value("${amazon.dynamodb.endpoint}")
    private String amazonDynamoDBEndpoint;

    @Value("${amazon.dynamodb.region}")
    private String amazonAWSRegion;

    // En EKS se autenticará solo
    @Bean
    public AmazonDynamoDB amazonDynamoDB() {
        return AmazonDynamoDBClientBuilder.standard()
            .withRegion(Regions.US_EAST_2)
            .build();
    }
}
```

## Beneficios del Cambio
1.  **Compatibilidad:** Se alinea con la infraestructura `dynamodb.tf` ya desplegada.
2.  **Costos:** DynamoDB es Serverless y mucho más económico para cargas de trabajo variables que mantener un cluster DocumentDB encendido 24/7.
3.  **Escalabilidad:** DynamoDB escala automáticamente sin gestión de servidores.
