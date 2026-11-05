model class4

global {
    // Number of cows at start
    int initial_cows <- 5;
    // Number of sheep at start
    int initial_sheep <- 3;
    // Number of goats at start
    int initial_goats <- 2;
    // Transparency of action areas, 0 solid to 1 invisible
    float area_transparency <- 0.7;

    init {
        create cows number: initial_cows;
        create sheep number: initial_sheep;
        create goats number: initial_goats;
    }
}

// Static grass cells covering the environment
grid grassland width: 50 height: 50 {
    // Grass amount, 0.0 to 10.0
    float biomass <- rnd(0.0, 10.0);

    // Cell colour, greener with more grass
    rgb color <- rgb(0, int(255 * (biomass / 10.0)), 0);
}

// Brown cow at a random location, moving by correlated random walk
species cows skills: [moving] {
    // Cow speed per step
    float speed <- 2.0;
    // Space the cow can reach next step
    geometry action_area;

    init {
        location <- any_location_in(world);
    }

    // Correlated random walk, up to 45 degrees either side of the heading
    reflex move {
        do wander amplitude: 90.0;
    }

    // Action area is a cone of radius speed around the heading
    reflex update_action_area {
        action_area <- circle(speed) intersection cone(heading - 45, heading + 45);
    }

    aspect base {
        draw square(1.5) color: #brown;
    }

    aspect action_neighbourhood {
        if (action_area != nil) {
            draw action_area color: #brown;
        }
    }
}

// Black sheep at a random location, walking south and bouncing at the edges
species sheep skills: [moving] {
    // Sheep speed per step
    float speed <- 1.0;
    // Space the sheep can reach next step
    geometry action_area;

    init {
        location <- any_location_in(world);
        heading <- 90.0;
    }

    // Walk straight along the heading; move reverses it at the world edge
    reflex move {
        do move;
    }

    // Action area is a line of length speed along the heading
    reflex update_action_area {
        action_area <- line(location, location + {speed * cos(heading), speed * sin(heading)});
    }

    aspect base {
        draw circle(0.6) color: #black;
    }

    aspect action_neighbourhood {
        if (action_area != nil) {
            draw action_area + 0.15 color: #black;
        }
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
    // Space the goat can reach next step
    geometry action_area;

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

    // Action area is the line to the current target, cut to length speed
    reflex update_action_area {
        action_area <- line(location, bounce_steps > 0 ? start_point : {0, 0}) intersection circle(speed);
    }

    aspect base {
        draw triangle(1.0) color: #yellow border: #black;
    }

    aspect action_neighbourhood {
        if (action_area != nil) {
            draw action_area + 0.15 color: #yellow;
        }
    }
}

experiment class4_simulation type: gui {
    output {
        display map {
            grid grassland border: #darkgreen;
            species cows aspect: base;
            species sheep aspect: base;
            species goats aspect: base;
            species cows aspect: action_neighbourhood transparency: area_transparency;
            species sheep aspect: action_neighbourhood transparency: area_transparency;
            species goats aspect: action_neighbourhood transparency: area_transparency;
        }
    }
}
