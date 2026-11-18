model class5

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
    // Distance the cow travelled in the first step, -1 until that step is done
    float first_step_distance <- -1.0;
    // Space the cow can reach next step
    geometry action_area;

    init {
        location <- any_location_in(world);
    }

    // Correlated random walk, up to 45 degrees either side of the heading; the first step's length is saved
    reflex move {
        point previous_location <- location;
        do wander amplitude: 90.0;
        if (cycle = 0) {
            first_step_distance <- previous_location distance_to location;
        }
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
    // Distance the sheep travelled in the first step, -1 until that step is done
    float first_step_distance <- -1.0;
    // Space the sheep can reach next step
    geometry action_area;

    init {
        location <- any_location_in(world);
        heading <- 90.0;
    }

    // Walk straight south to the bottom edge and stop there, no bounce; the first step's length is saved
    reflex move {
        point previous_location <- location;
        do goto target: {location.x, world.shape.height};
        if (cycle = 0) {
            first_step_distance <- previous_location distance_to location;
        }
    }
    
//    using do move
//    reflex move when: location.y + speed <= world.shape.height {
//	    do move heading: 90.0;
//	}
    

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

// Yellow goat at a random location, walking to the origin and stopping there
species goats skills: [moving] {
    // Goat speed per step
    float speed <- 0.5;
    // Total distance the goat has walked so far
    float total_distance <- 0.0;
    // Step when the goat reached the origin, -1 while still walking
    int arrival_step <- -1;
    // Space the goat can reach next step
    geometry action_area;

    init {
        location <- any_location_in(world);
    }

    // Walk to the origin and stop there, adding each step's length to total_distance and noting the arrival step
    reflex move when: location distance_to {0, 0} > 0.001 {
        point previous_location <- location;
        do goto target: {0, 0};
        total_distance <- total_distance + (previous_location distance_to location);
        if (location distance_to {0, 0} <= 0.001) {
            arrival_step <- cycle;
        }
    }

    // Action area is the line to the origin, cut to length speed and enlarged by goat_area_scale; none once stopped
    reflex update_action_area {
        action_area <- (location distance_to {0, 0} > 0.001) ? line(location, {0, 0}) intersection circle(speed * goat_area_scale) : nil;
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

experiment class5_simulation type: gui {
    output {
        display map {
            species cows aspect: base;
            species sheep aspect: base;
            species goats aspect: base;
            species cows aspect: action_neighbourhood transparency: area_transparency;
            species sheep aspect: action_neighbourhood transparency: area_transparency;
            species goats aspect: action_neighbourhood transparency: area_transparency;
        }

        // Goal 1: mean total distance travelled by the goats over time
        display goat_distance_chart type:2d{
            chart "Goats: mean total distance travelled" type: series x_label: "Step" y_label: "Distance" {
                // Dot only at the step a goat stops, so each change of stage is marked; listed first so it is drawn on top of the line
                data "Goat stops" value: (goats one_matches (each.arrival_step = cycle)) ? mean(goats collect each.total_distance) : nil
                    color: #black line_visible: false marker_shape: marker_circle marker_size: 2;
                data "Goats mean" value: mean(goats collect each.total_distance) color: #yellow;
            }
        }

        // Goal 2: mean distance travelled by cows and sheep in the first step
        display first_step_chart type:2d {
            chart "Mean distance travelled in the first step" type: scatter x_label: "Step" y_label: "Distance" {
                data "Cows mean" value: (cows none_matches (each.first_step_distance < 0)) ? {1, mean(cows collect each.first_step_distance)} : nil color: #brown marker_shape: marker_circle;
                data "Sheep mean" value: (sheep none_matches (each.first_step_distance < 0)) ? {1, mean(sheep collect each.first_step_distance)} : nil color: #black marker_shape: marker_circle;
            }
        }
    }
}
