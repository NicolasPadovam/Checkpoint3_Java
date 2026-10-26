package br.com.fiap.vitorportelaf.modelocarro.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;

@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI openAPI() {
        return new OpenAPI().info(new Info()
                .title("Modelo Carro API")
                .version("v1")
                .description("API REST para gerenciamento de marcas e modelos de carros - Checkpoint 3"));
    }
}
