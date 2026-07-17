package tech.omnisyserp.desktop.config;

import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.web.client.RestTemplate;

@Configuration
@EnableConfigurationProperties(BackendProperties.class)
public class AppConfig {

    @Bean
    RestTemplate restTemplate(BackendProperties props) {
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(props.getApi().getConnectTimeout());
        factory.setReadTimeout(props.getApi().getReadTimeout());
        return new RestTemplate(factory);
    }
}
