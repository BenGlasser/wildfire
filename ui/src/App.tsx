import { useState } from 'react'
import { Map } from './components/map'
import { useGeoSocket } from './hooks/websocket'
import './App.css'

function App() {
  const [count, setCount] = useState(0)
  const { geojson, status } = useGeoSocket('ws://localhost:8080/ws')


  return (
    <>
      <Map geojson={geojson} />
    </>
  )
}

export default App
