model class4

global {
    // Number of cows at start
    int initial_cows <- 5;
    // Number of sheep at start
    int initial_sheep <- 3;
    // Number of goats at start
    int initial_goats <- 2;

    init {
        create cows number: initial_cows;
        create sheep number: initial_sheep;
        create goats number: initial_goats;
    }
}

// Brown cow at a random location, moving by correlated random walk
species cows skills: [moving] {
    // Cow speed per step
    float speed <- 2.0;

    init {
        location <- any_location_in(world);
    }

    // Correlated random walk, up to 45 degrees either side of the heading
    reflex move {
        do wander amplitude: 90.0;
    }

    aspect base {
        draw circle(2) color: #brown;
    }
}

// Black sheep at a random location
species sheep {
    init {
        location <- any_location_in(world);
    }

    aspect base {
        draw circle(2) color: #black;
    }
}

// Yellow goat at a random location
species goats {
    init {
        location <- any_location_in(world);
    }

    aspect base {
        draw circle(2) color: #yellow;
    }
}

experiment class4_simulation type: gui {
    output {
        display map {
            species cows aspect: base;
            species sheep aspect: base;
            species goats aspect: base;
        }
    }
}
