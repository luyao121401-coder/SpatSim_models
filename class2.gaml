model AfricanSavanna

global {
    // Initial conditions
    int initial_lions <- 20;
    int initial_zebras <- 20;
    
    init {
        // Create the initial populations
        create lion number: initial_lions;
        create zebra number: initial_zebras;
    }
}

// Grassland CA: Grid covering the entire environment
grid grassland width: 50 height: 50 {
    // Initial biomass randomly generated between 0.0 and 10.0
    float biomass <- rnd(0.0, 10.0);
    
    // Optional: Color the grid based on the biomass amount (darker green = more biomass)
    rgb color <- rgb(0, int(255 * (biomass / 10.0)), 0);
}

species lion {
    // Random initial location
    init {
        location <- any_location_in(world);
    }
    
    aspect base {
        draw circle(1) color: #red border: #black;
    }
}

species zebra {
    // Random initial location
    init {
        location <- any_location_in(world);
    }
    
    aspect base {
        draw circle(1) color: #white border: #black;
    }
}

experiment savanna_simulation type: gui {
    output {
        display map {
            grid grassland border: #darkgreen;
            species zebra aspect: base;
            species lion aspect: base;
        }
    }
}