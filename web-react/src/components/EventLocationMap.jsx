import { useState } from 'react';
import OpenStreetMap from './OpenStreetMap';
import './OpenStreetMap.css';

export default function EventLocationMap({ 
  location, 
  latitude = 36.8065, 
  longitude = 10.1815,
  width = '100%',
  height = '200px'
}) {
  const [showMap, setShowMap] = useState(false);

  const toggleMap = () => {
    setShowMap(!showMap);
  };

  return (
    <div style={{ marginTop: '12px' }}>
      <div 
        onClick={toggleMap}
        style={{
          display: 'flex',
          alignItems: 'center',
          gap: '8px',
          cursor: 'pointer',
          padding: '8px 12px',
          backgroundColor: '#f8f9fa',
          borderRadius: '8px',
          border: '1px solid #e9ecef',
          transition: 'all 0.2s ease'
        }}
        onMouseEnter={(e) => {
          e.currentTarget.style.backgroundColor = '#e9ecef';
        }}
        onMouseLeave={(e) => {
          e.currentTarget.style.backgroundColor = '#f8f9fa';
        }}
      >
        <span style={{ fontSize: '16px' }}>🗺️</span>
        <span style={{ fontSize: '13px', color: '#495057', fontWeight: '500' }}>
          {showMap ? 'Masquer la carte' : 'Afficher la carte'}
        </span>
        <div style={{ marginLeft: 'auto' }}>
          <span style={{ fontSize: '12px', color: '#6c757d' }}>
            {showMap ? '▲' : '▼'}
          </span>
        </div>
      </div>

      {showMap && (
        <div style={{ 
          marginTop: '12px',
          border: '1px solid #e9ecef',
          borderRadius: '8px',
          overflow: 'hidden',
          boxShadow: '0 2px 8px rgba(0,0,0,0.1)'
        }}>
          <OpenStreetMap
            latitude={latitude}
            longitude={longitude}
            zoom={15}
            width={width}
            height={height}
            markers={[
              {
                lat: latitude,
                lng: longitude,
                popup: location || 'Localisation de l\'événement'
              }
            ]}
            className="openstreetmap-container"
          />
          
          {location && (
            <div style={{
              padding: '12px',
              backgroundColor: 'white',
              borderTop: '1px solid #e9ecef'
            }}>
              <div style={{ fontSize: '12px', color: '#495057' }}>
                <strong>📍 Adresse:</strong> {location}
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}