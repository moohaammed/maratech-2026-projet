import { useEffect, useRef, useState } from 'react';

export default function OpenStreetMap({
  latitude = 36.8065, // Default to Tunis
  longitude = 10.1815,
  zoom = 13,
  width = '100%',
  height = '300px',
  markers = [],
  onMapClick = null,
  draggable = false,
  className = ''
}) {
  const mapRef = useRef(null);
  const mapInstanceRef = useRef(null);
  const [mapLoaded, setMapLoaded] = useState(false);
  const [error, setError] = useState(null);
  const [retryCount, setRetryCount] = useState(0);

  useEffect(() => {
    console.log('OpenStreetMap: Initializing with coordinates:', latitude, longitude);

    // Load Leaflet CSS and JS
    const loadLeaflet = async () => {
      try {
        if (window.L) {
          console.log('OpenStreetMap: Leaflet already loaded, initializing map immediately');
          // Add a small delay to ensure DOM is ready
          setTimeout(() => initializeMap(), 100);
          return;
        }

        // Load CSS
        const link = document.createElement('link');
        link.rel = 'stylesheet';
        link.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css';
        link.onload = () => console.log('OpenStreetMap: Leaflet CSS loaded');
        link.onerror = () => console.error('OpenStreetMap: Failed to load Leaflet CSS');
        document.head.appendChild(link);

        const script = document.createElement('script');
        script.src = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js';
        script.onload = () => {
          console.log('OpenStreetMap: Leaflet script loaded successfully');
          // Add a small delay to ensure DOM is ready after script loads
          setTimeout(() => initializeMap(), 100);
        };
        script.onerror = () => {
          console.error('OpenStreetMap: Failed to load Leaflet script');
          setError('Failed to load map library');
        };
        document.head.appendChild(script);
      } catch (err) {
        setError('Error loading map: ' + err.message);
      }
    };

    const initializeMap = () => {
      console.log('OpenStreetMap: initializeMap called, mapRef:', mapRef.current, 'window.L:', !!window.L);
      console.log('OpenStreetMap: mapRef.current element:', mapRef.current);
      if (!mapRef.current) {
        console.error('OpenStreetMap: mapRef.current is null');
        return;
      }
      if (!window.L) {
        console.error('OpenStreetMap: window.L is not available');
        return;
      }

      // Check if the element is actually in the DOM and has dimensions
      const rect = mapRef.current.getBoundingClientRect();
      console.log('OpenStreetMap: Element dimensions:', rect);

      // Initialize map
      console.log('OpenStreetMap: Creating map with view:', [latitude, longitude], 'zoom:', zoom);
      const map = window.L.map(mapRef.current).setView([latitude, longitude], zoom);
      mapInstanceRef.current = map;
      console.log('OpenStreetMap: Map created successfully');

      // Add tile layer from OpenStreetMap
      console.log('OpenStreetMap: Adding tile layer...');
      window.L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
        maxZoom: 19,
      }).addTo(map);
      console.log('OpenStreetMap: Tile layer added successfully');

      // Add markers
      console.log('OpenStreetMap: Adding markers:', markers);
      markers.forEach(marker => {
        const leafletMarker = window.L.marker([marker.lat, marker.lng])
          .addTo(map)
          .bindPopup(marker.popup || 'Location');

        if (marker.draggable) {
          leafletMarker.dragging.enable();
        }
      });
      console.log('OpenStreetMap: Markers added successfully');

      // Handle map clicks
      if (onMapClick) {
        map.on('click', (e) => {
          onMapClick(e.latlng.lat, e.latlng.lng);
        });
      }

      setMapLoaded(true);
      console.log('OpenStreetMap: Map loaded successfully');
    };

    loadLeaflet();

    return () => {
      // Cleanup
      if (mapInstanceRef.current) {
        mapInstanceRef.current.remove();
        mapInstanceRef.current = null;
      }
    };
  }, [latitude, longitude, zoom, markers, onMapClick, retryCount]);

  // Update map center when coordinates change
  useEffect(() => {
    if (mapInstanceRef.current && mapLoaded) {
      mapInstanceRef.current.setView([latitude, longitude], zoom);
    }
  }, [latitude, longitude, zoom, mapLoaded]);

  // Update markers when they change
  useEffect(() => {
    if (!mapInstanceRef.current || !mapLoaded || !window.L) return;

    // Clear existing markers
    mapInstanceRef.current.eachLayer((layer) => {
      if (layer instanceof window.L.Marker) {
        mapInstanceRef.current.removeLayer(layer);
      }
    });

    // Add new markers
    markers.forEach(marker => {
      const leafletMarker = window.L.marker([marker.lat, marker.lng])
        .addTo(mapInstanceRef.current)
        .bindPopup(marker.popup || 'Location');

      if (marker.draggable) {
        leafletMarker.dragging.enable();
      }
    });
  }, [markers, mapLoaded]);

  const handleRetry = () => {
    setRetryCount(prev => prev + 1);
    setError(null);
    setMapLoaded(false);
  };

  const handleStaticMapClick = () => {
    if (onMapClick) {
      // Use the center coordinates when clicking on static map
      onMapClick(latitude, longitude);
    }
  };

  // If error, show error state with retry button
  return (
    <div style={{ position: 'relative', width, height }}>
      {error && (
        <div
          style={{
            position: 'absolute',
            top: 0,
            left: 0,
            width: '100%',
            height: '100%',
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            backgroundColor: '#f0f0f0',
            border: '1px solid #ddd',
            borderRadius: '4px',
            color: '#666',
            fontSize: '14px',
            padding: '16px',
            boxSizing: 'border-box',
            zIndex: 1000
          }}
        >
          <div style={{ marginBottom: '12px' }}>
            ❌ Erreur de carte: {error}
          </div>
          <button
            onClick={handleRetry}
            style={{
              padding: '8px 16px',
              backgroundColor: '#007bff',
              color: 'white',
              border: 'none',
              borderRadius: '4px',
              cursor: 'pointer',
              fontSize: '14px'
            }}
          >
            Réessayer
          </button>
        </div>
      )}

      {!mapLoaded && !error && (
        <div
          style={{
            position: 'absolute',
            top: 0,
            left: 0,
            width: '100%',
            height: '100%',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            backgroundColor: '#f9f9f9',
            border: '1px solid #ddd',
            borderRadius: '4px',
            color: '#666',
            fontSize: '14px',
            zIndex: 1000
          }}
        >
          🗺️ Chargement de la carte...
        </div>
      )}

      <div
        ref={mapRef}
        style={{ width: '100%', height: '100%', visibility: mapLoaded ? 'visible' : 'hidden' }}
        className={className}
      />
    </div>
  );
}