model AfricanSavanna

global {
    // Number of lions at start
    int initial_lions <- 20;
    // Number of zebras at start
    int initial_zebras <- 20;
    // Ages of all living lions
    list<int> age_list <- [];
    // Steps per simulated year
    int steps_per_year <- 52;
    // Shared lion colour: red at mean age 1, white at mean age 60
    rgb lion_colour -> rgb(255, int(255 * (mean(age_list) - 1) / 59), int(255 * (mean(age_list) - 1) / 59));

    init {
        create lion number: initial_lions;
        create zebra number: initial_zebras;

        ask lion {
            add age to: age_list;
        }
    }

    // Report count, minimum, mean and maximum age each step
    reflex report_ages when: !empty(age_list) {
        write "Step " + cycle + " | lions: " + length(age_list) + " | min: " + min(age_list) + " | mean: " + (mean(age_list) with_precision 2) + " | max: " + max(age_list);
    }
}

// Grass cells covering the environment
grid grassland width: 50 height: 50 {
    // Grass amount, 0.0 to 10.0
    float biomass <- rnd(0.0, 10.0);

    // Cell colour, greener with more grass
    rgb color <- rgb(0, int(255 * (biomass / 10.0)), 0);

    // Grass grows 0.1 per step, max 10.0
    reflex grow {
        biomass <- biomass + 0.1;

        if (biomass > 10.0) {
            biomass <- 10.0;
        }
        color <- rgb(0, int(255 * (biomass / 10.0)), 0);
    }
}

// Predator that wanders and hunts zebras
species lion skills: [moving] {
    // Lion energy, starts at 2000-3500
    int energy <- rnd(2000, 3500);
    // Lion age in years, starts at 1-60
    int age <- rnd(1, 60);

    init {
        location <- any_location_in(world);
    }

    // Age by 1 each year, replacing the previous age in the list
    reflex update_age when: cycle mod steps_per_year = 0 {
        remove age from: age_list;
        age <- age + 1;
        add age to: age_list;
    }

    // When older than 60, have a baby here, then die
    reflex die_of_old_age when: age > 60 {
        create lion {
            age <- 0;
            location <- myself.location;
            add age to: age_list;
        }
        remove age from: age_list;
        do die;
    }

    // Wander and lose 1 energy per step
    reflex move {
        do wander;
        energy <- energy - 1;
    }

    // Eat zebras within distance 1, gain 300 energy each
    reflex hunt {
        ask zebra at_distance 1 {
            myself.energy <- myself.energy + 300;
            do die;
        }
    }

    // Die when energy reaches 0
    reflex starve when: energy <= 0 {
        remove age from: age_list;
        do die;
    }

    aspect base {
        draw circle(3) color: lion_colour border: #black;
    }
}

// Prey that wanders and eats grass
species zebra skills: [moving] {
    init {
        location <- any_location_in(world);
    }

    // Wander randomly
    reflex move {
        do wander;
    }

    // Eat all grass on the current cell
    reflex eat {
        grassland current_cell <- grassland(location);

        if (current_cell != nil and current_cell.biomass > 0) {
            current_cell.biomass <- 0.0;
            current_cell.color <- rgb(0, 0, 0);
        }
    }

    aspect base {
        draw triangle(2) color: #gray border: #black;
    }
}

experiment savanna_simulation type: gui {
    parameter "Steps per year" var: steps_per_year min: 1 max: 52 step: 1;

    output {
        display map {
            grid grassland border: #darkgreen;
            species zebra aspect: base;
            species lion aspect: base;
        }
    }
}
