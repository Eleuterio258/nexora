package tech.omnisyserp.desktop.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class PaginatedUsersDto {
    private List<UserDto> items;
    private int page;
    private int page_size;
    private int total;
}
