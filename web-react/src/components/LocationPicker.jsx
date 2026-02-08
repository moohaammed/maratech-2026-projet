import { useEffect, useState, useCallback } from "react";
import OpenStreetMap from "./OpenStreetMap";
import "./OpenStreetMap.css";

export default function LocationPicker({
  value = "",
  onChange = () => { },
  onCoordinatesChange,
  latitude = 36.8065,
  longitude = 10.1815,
  placeholder = "Recherchez une adresse...",
}) {
  // Add error boundary
  try {
    const [searchQuery, setSearchQuery] = useState(value || "");
    const [selectedLocation, setSelectedLocation] = useState(() => ({
      lat: latitude,
      lng: longitude,
      address: value,
    }));
    const [isSearching, setIsSearching] = useState(false);
    const [useManualMode, setUseManualMode] = useState(false);
    const [manualLat, setManualLat] = useState(String(latitude));
    const [manualLng, setManualLng] = useState(String(longitude));

    // Keep internal state in sync when parent value changes
    useEffect(() => {
      setSearchQuery(value || "");
      setSelectedLocation((prev) =>
        prev.address === value ? prev : { ...prev, address: value || "" }
      );
    }, [value]);

    // Auto-search when user types (debounced)
    useEffect(() => {
      if (!searchQuery || searchQuery.length < 3) return;

      const timer = setTimeout(() => {
        searchLocation();
      }, 1000); // Wait 1 second after user stops typing

      return () => clearTimeout(timer);
    }, [searchQuery]); // Remove searchLocation dependency to avoid circular dependency

    const fetchWithTimeout = useCallback(async (url, options = {}, timeoutMs = 10000) => {
      const controller = new AbortController();
      const id = setTimeout(() => controller.abort(), timeoutMs);

      try {
        const res = await fetch(url, {
          ...options,
          signal: controller.signal,
          headers: {
            ...(options.headers || {}),
            // NOTE: Browsers often ignore custom User-Agent; it's fine to keep it,
            // but don't rely on it.
            "User-Agent": "Maratech-Event-Manager/1.0",
          },
        });
        return res;
      } finally {
        clearTimeout(id);
      }
    }, []);

    const applyLocation = useCallback(
      ({ lat, lng, address }) => {
        const newLoc = { lat, lng, address };
        setSelectedLocation(newLoc);
        setSearchQuery(address || "");
        onChange(address || "");
        onCoordinatesChange?.({ lat, lng });
      },
      [onChange, onCoordinatesChange]
    );

    // Geocoding using Nominatim
    const searchLocation = useCallback(async () => {
      if (!searchQuery.trim()) return;

      setIsSearching(true);
      try {
        const url = `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(
          searchQuery
        )}&limit=5&addressdetails=1&countrycodes=tn`;

        const response = await fetchWithTimeout(url, {}, 10000);

        if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);

        const data = await response.json();

        if (Array.isArray(data) && data.length > 0) {
          const first = data[0];
          applyLocation({
            lat: parseFloat(first.lat),
            lng: parseFloat(first.lon),
            address: first.display_name,
          });
        } else {
          alert("Adresse non trouvée. Essayez une autre recherche.");
        }
      } catch (error) {
        console.error("=== ERREUR DE GÉOCODAGE ===", error);

        let errorMessage = error?.message || "Erreur inconnue";
        if (error?.name === "AbortError") {
          errorMessage = "La recherche a pris trop de temps. Veuillez réessayer.";
        } else if (String(errorMessage).includes("Failed to fetch")) {
          errorMessage =
            "Erreur de connexion. Vérifiez votre connexion internet ou cliquez sur la carte.";
        }

        alert(`Erreur lors de la recherche de l'adresse: ${errorMessage}`);

        // Switch to manual mode on network/timeout issues
        if (error?.name === "AbortError" || String(errorMessage).includes("Failed to fetch")) {
          setUseManualMode(true);
        }
      } finally {
        setIsSearching(false);
      }
    }, [searchQuery, fetchWithTimeout, applyLocation]);

    // Reverse geocoding when clicking on map
    const handleMapClick = useCallback(
      async (lat, lng) => {
        try {
          const url = `https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lng}&addressdetails=1`;
          const response = await fetchWithTimeout(url, {}, 10000);

          if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);

          const data = await response.json();

          if (data?.display_name) {
            applyLocation({ lat, lng, address: data.display_name });
            return;
          }

          // If no display_name, fallback to coords
          applyLocation({
            lat,
            lng,
            address: `Coordonnées: ${lat.toFixed(6)}, ${lng.toFixed(6)}`,
          });
        } catch (error) {
          console.warn("Reverse geocoding failed, fallback to coordinates:", error);
          applyLocation({
            lat,
            lng,
            address: `Coordonnées: ${lat.toFixed(6)}, ${lng.toFixed(6)}`,
          });
        }
      },
      [fetchWithTimeout, applyLocation]
    );

    const handleKeyDown = (e) => {
      if (e.key === "Enter") {
        e.preventDefault();
        searchLocation();
      }
    };

    const handleManualCoordinates = () => {
      const lat = parseFloat(manualLat);
      const lng = parseFloat(manualLng);

      if (Number.isNaN(lat) || Number.isNaN(lng) || lat < -90 || lat > 90 || lng < -180 || lng > 180) {
        alert(
          "Coordonnées invalides. Veuillez entrer des valeurs valides.\nLatitude: -90 à 90\nLongitude: -180 à 180"
        );
        return;
      }

      applyLocation({
        lat,
        lng,
        address: `Coordonnées: ${lat.toFixed(6)}, ${lng.toFixed(6)}`,
      });
    };

    return (
      <div className="location-picker-container">
        <div style={{ marginBottom: "12px" }}>
          <label
            style={{
              display: "block",
              marginBottom: "8px",
              fontSize: "14px",
              color: "#666",
              fontWeight: "600",
            }}
          >
            Localisation
          </label>

          <div style={{ display: "flex", gap: "8px", marginBottom: "12px" }}>
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              onKeyDown={handleKeyDown}
              placeholder={placeholder}
              className="location-search-input"
              style={{
                backgroundImage: isSearching ? 'url("data:image/svg+xml,%3Csvg xmlns=\'http://www.w3.org/2000/svg\' width=\'20\' height=\'20\' viewBox=\'0 0 20 20\'%3E%3Ccircle cx=\'10\' cy=\'10\' r=\'8\' fill=\'none\' stroke=\'%23666\' stroke-width=\'2\' stroke-dasharray=\'4,4\'/%3E%3C/svg%3E")' : 'none',
                backgroundRepeat: 'no-repeat',
                backgroundPosition: 'right 8px center',
                backgroundSize: '16px'
              }}
            />
            <button
              type="button"
              onClick={searchLocation}
              disabled={isSearching}
              className="location-search-button"
            >
              {isSearching ? "Recherche..." : "Rechercher"}
            </button>
          </div>

          <div style={{ marginBottom: "12px" }}>
            <button
              type="button"
              onClick={() => setUseManualMode((v) => !v)}
              style={{
                backgroundColor: useManualMode ? "#444" : "#666",
                color: "white",
                border: "none",
                padding: "6px 12px",
                borderRadius: "4px",
                fontSize: "12px",
                cursor: "pointer",
              }}
            >
              {useManualMode ? "Mode manuel activé" : "Passer en mode manuel"}
            </button>
          </div>

          {useManualMode && (
            <div>
              <p
                style={{
                  fontSize: "12px",
                  color: "#666",
                  marginBottom: "8px",
                  fontStyle: "italic",
                }}
              >
                Entrez les coordonnées manuellement. (Le clic sur la carte reste possible.)
              </p>

              <div style={{ display: "flex", gap: "8px", marginBottom: "12px", alignItems: "center" }}>
                <input
                  type="number"
                  step="0.000001"
                  value={manualLat}
                  onChange={(e) => setManualLat(e.target.value)}
                  placeholder="Latitude"
                  style={{
                    flex: 1,
                    padding: "8px",
                    border: "1px solid #ddd",
                    borderRadius: "4px",
                    fontSize: "14px",
                  }}
                />
                <input
                  type="number"
                  step="0.000001"
                  value={manualLng}
                  onChange={(e) => setManualLng(e.target.value)}
                  placeholder="Longitude"
                  style={{
                    flex: 1,
                    padding: "8px",
                    border: "1px solid #ddd",
                    borderRadius: "4px",
                    fontSize: "14px",
                  }}
                />
                <button
                  type="button"
                  onClick={handleManualCoordinates}
                  style={{
                    backgroundColor: "#333",
                    color: "white",
                    border: "none",
                    padding: "8px 12px",
                    borderRadius: "4px",
                    fontSize: "14px",
                    cursor: "pointer",
                  }}
                >
                  Appliquer
                </button>
              </div>
            </div>
          )}
        </div>

        <div
          style={{
            border: "1px solid #ddd",
            borderRadius: "8px",
            overflow: "hidden",
            boxShadow: "0 2px 4px rgba(0,0,0,0.1)",
            position: "relative",
            minHeight: "250px", // Ensure minimum height
            backgroundColor: "#f9f9f9" // Light background to show container
          }}
        >
          {isSearching && (
            <div style={{
              position: "absolute",
              top: "8px",
              right: "8px",
              backgroundColor: "rgba(255,255,255,0.9)",
              padding: "4px 8px",
              borderRadius: "4px",
              fontSize: "12px",
              zIndex: 1000,
              color: "#666"
            }}>
              🗺️ Recherche en cours...
            </div>
          )}
          <OpenStreetMap
            key={`${selectedLocation.lat}-${selectedLocation.lng}`}
            latitude={selectedLocation.lat}
            longitude={selectedLocation.lng}
            onMapClick={handleMapClick}  // keep map click always available
            zoom={15}
            height="250px"
            markers={[
              {
                lat: selectedLocation.lat,
                lng: selectedLocation.lng,
                popup: selectedLocation.address || "Localisation sélectionnée",
              },
            ]}
            className="openstreetmap-container"
          />
        </div>

        {selectedLocation.address && <div className="location-address-display">📍 {selectedLocation.address}</div>}
      </div>
    );
  } catch (error) {
    console.error('LocationPicker Error:', error);
    return (
      <div style={{ padding: '16px', backgroundColor: '#fee', border: '1px solid #fcc', borderRadius: '8px', color: '#c33' }}>
        <strong>Erreur dans le sélecteur de localisation:</strong><br />
        {error.message}<br />
        <small>Utilisez les coordonnées manuelles ou rechargez la page.</small>
      </div>
    );
  }
}
