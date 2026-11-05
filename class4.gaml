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

// Black sheep at a random location, walking south and bouncing at the edges
species sheep skills: [moving] {
    // Sheep speed per step
    float speed <- 1.0;

    init {
        location <- any_location_in(world);
        heading <- 90.0;
    }

    // Walk straight along the heading; move reverses it at the world edge
    reflex move {
        do move;
    }

    aspect base {
        draw circle(2) color: #black;
    }
}

// Yellow goat at a random location, walking to the origin and bouncing back
species goats skills: [moving] {
    // Goat speed per step
    float speed <- 0.5;
    // Where the goat started, used to walk back the way it came
    point start_point;
    // Steps left to walk back after bouncing at the origin
    int bounce_steps <- 0;

    init {
        location <- any_location_in(world);
        start_point <- location;
    }

    // Walk to the origin, then walk back the way it came for 10 steps
    reflex move {
        if (bounce_steps > 0) {
            do goto target: start_point;
            bounce_steps <- bounce_steps - 1;
        } else {
            do goto target: {0, 0};
            if (location distance_to {0, 0} < 0.001) {
                bounce_steps <- 10;
            }
        }
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
