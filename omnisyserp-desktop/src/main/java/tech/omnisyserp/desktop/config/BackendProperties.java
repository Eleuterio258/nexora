package tech.omnisyserp.desktop.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "backend")
@Getter
@Setter
public class BackendProperties {

    private Api api = new Api();
    private Device device = new Device();

    @Getter
    @Setter
    public static class Api {
        private String url = "http://localhost:8000";
        private int connectTimeout = 5000;
        private int readTimeout = 30000;
        
        // Helper methods for UI
        public int getTimeoutSeconds() {
            return readTimeout / 1000;
        }
        
        public void setTimeoutSeconds(int seconds) {
            this.readTimeout = seconds * 1000;
            this.connectTimeout = Math.min(5000, this.readTimeout / 6);
        }
    }

    @Getter
    @Setter
    public static class Device {
        private String id = "00000000-0000-0000-0000-000000000099";
    }
}
