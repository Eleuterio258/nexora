// Package geo contém utilitários geográficos partilhados entre módulos
// (validação de geofence para marcação de assiduidade, etc.).
package geo

import "math"

const earthRadiusMeters = 6371000.0

// HaversineMeters calcula a distância em metros entre duas coordenadas
// (latitude/longitude em graus decimais).
func HaversineMeters(lat1, lon1, lat2, lon2 float64) float64 {
	toRad := func(deg float64) float64 { return deg * math.Pi / 180 }

	dLat := toRad(lat2 - lat1)
	dLon := toRad(lon2 - lon1)
	a := math.Sin(dLat/2)*math.Sin(dLat/2) +
		math.Cos(toRad(lat1))*math.Cos(toRad(lat2))*math.Sin(dLon/2)*math.Sin(dLon/2)
	c := 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))
	return earthRadiusMeters * c
}
