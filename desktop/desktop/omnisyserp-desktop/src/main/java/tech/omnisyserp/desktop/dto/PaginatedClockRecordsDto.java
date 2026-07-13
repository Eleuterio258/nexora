package tech.omnisyserp.desktop.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class PaginatedClockRecordsDto {
    private List<ClockRecordDto> items;
    private int page;
    private int page_size;
    private int total;
}
