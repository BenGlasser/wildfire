import { feature } from "topojson-client";
import usAtlas from "us-atlas/states-10m.json";
import type { Topology, GeometryCollection } from "topojson-specification";
import type { Feature, FeatureCollection, Geometry } from "geojson";

type StateProps = { name?: string };

const topology = usAtlas as unknown as Topology<{
  states: GeometryCollection<StateProps>;
}>;

export const usStates: FeatureCollection<Geometry, StateProps> = feature(
  topology,
  topology.objects.states
) as FeatureCollection<Geometry, StateProps>;

export type { Feature, FeatureCollection, StateProps };
