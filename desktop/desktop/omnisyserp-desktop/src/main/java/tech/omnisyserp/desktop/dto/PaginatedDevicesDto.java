package tech.omnisyserp.desktop.dto;

import lombok.Data;
import java.util.List;

@Data
public class PaginatedDevicesDto {
    private List<DeviceDto> items;
    private int page;
    private int page_size;
    private int total;
}
