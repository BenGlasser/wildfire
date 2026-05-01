import { Map } from './components/map'
import { useGeoSocket } from './hooks/websocket'
import './App.css'

const wsUrl = `${location.protocol === 'https:' ? 'wss' : 'ws'}://${location.host}/ws/incidents`

function App() {
  const { geojson, status: _status } = useGeoSocket(wsUrl)


  return (
    <>
      <Map geojson={geojson} />
    </>
  )
}

export default App
