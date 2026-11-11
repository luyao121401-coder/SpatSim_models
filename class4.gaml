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
    // Display scale for action areas, so they show beyond the agent shapes
    float area_scale <- 4.0;
    // Larger display scale for goats, the slowest agents
    float goat_area_scale <- 10.0;

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
    // Space the cow can reach next step
    geometry action_area;

    init {
        location <- any_location_in(world);
    }

    // Correlated random walk, up to 45 degrees either side of the heading
    reflex move {
        do wander amplitude: 90.0;
    }

    // Action area is a cone of radius speed around the heading, enlarged by area_scale
    reflex update_action_area {
        action_area <- circle(speed * area_scale) intersection cone(heading - 45, heading + 45);
    }

    aspect base {
        draw square(3.0) color: #brown;
    }

    aspect action_neighbourhood {
        if (action_area != nil) {
            draw action_area color: #brown;
        }
    }
}

// Black sheep at a random location, walking south and stopping at the bottom edge
species sheep skills: [moving] {
    // Sheep speed per step
    float speed <- 1.0;
    // Space the sheep can reach next step
    geometry action_area;

    init {
        location <- any_location_in(world);
        heading <- 90.0;
    }

    // Walk straight south to the bottom edge and stop there, no bounce
    reflex move {
        do goto target: {location.x, world.shape.height};
    }

    // Action area is a line of length speed along the heading, enlarged by area_scale
    reflex update_action_area {
        action_area <- line(location, location + {speed * area_scale * cos(heading), speed * area_scale * sin(heading)});
    }

    aspect base {
        draw circle(1.2) color: #black;
    }

    aspect action_neighbourhood {
        if (action_area != nil) {
            draw action_area + 0.15 color: #black;
        }
    }
}

// Yellow goat starting near the corner farthest from the origin, walking to the origin and bouncing back
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
        // First goat near the right edge, second near the bottom edge, so they do not overlap
        location <- (int(self) = 0) ? {world.shape.width, world.shape.height - 5} : {world.shape.width - 5, world.shape.height};
        start_point <- location;
    }

    // Walk to the origin, then walk back the way it came for 10 steps, then return
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

    // Action area is the line to the current target, cut to length speed and enlarged by goat_area_scale
    reflex update_action_area {
        action_area <- line(location, bounce_steps > 0 ? start_point : {0, 0}) intersection circle(speed * goat_area_scale);
    }

    aspect base {
        draw triangle(2.0) color: #yellow border: #black;
    }

    aspect action_neighbourhood {
        if (action_area != nil) {
            draw action_area + 0.15 color: #yellow border: #black;
        }
    }
}

experiment class4_simulation type: gui {
    output {
        display map {
            species cows aspect: base;
            species sheep aspect: base;
            species goats aspect: base;
            species cows aspect: action_neighbourhood transparency: area_transparency;
            species sheep aspect: action_neighbourhood transparency: area_transparency;
            species goats aspect: action_neighbourhood transparency: area_transparency;
        }
    }
}
