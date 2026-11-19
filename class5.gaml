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
    // Pool of all cow direction changes between -45 and 45 degrees, growing every step
    list<float> cow_turn_angles <- [];
    // Step in which each value of cow_turn_angles happened (1 = first step), same order as cow_turn_angles
    list<int> cow_turn_steps <- [];
    // Goats' mean total distance after each number of steps, as {steps done, mean}, the data of the goat chart
    list<point> goat_distance_series <- [];
    // Number of this run (1, 2, 3, ...), written in every results row; set when the results are saved
    int run_number <- 0;
    // Folder where the end results are saved (absolute, so GAMA does not put them in its own workspace)
    string results_folder <- "E:/claude_workplace/SpatSim_models/results/";
    // True once the end results are saved, so they are written only once
    bool results_saved <- false;

    // Outline of the cow direction-change histogram as chart points: each 5 degree bin from -45 to 45 is drawn as
    // a block (left edge, up to its count, across, back down), so the bars sit side by side on a numeric x axis
    list<point> cow_turn_outline {
        list<int> counts <- empty(cow_turn_angles) ? list_with(18, 0) : (distribution_of(cow_turn_angles, 18, -45, 45) at "values");
        list<point> points <- [];
        loop i from: 0 to: 17 {
            float left <- -45.0 + 5.0 * i;
            points <- points + [{left, 0}, {left, counts[i]}, {left + 5.0, counts[i]}, {left + 5.0, 0}];
        }
        return points;
    }

    // Before the animals move, note the goats' mean total distance after the steps done so far (cycle = steps done)
    reflex record_goat_distance {
        add {cycle, mean(goats collect each.total_distance)} to: goat_distance_series;
    }

    // When every sheep is at the south edge and every goat at the origin, append the data behind each chart
    // and the end state to CSV files in results_folder, then pause the simulation
    reflex save_results when: !results_saved
            and (sheep all_match (world.shape.height - each.location.y <= 0.001))
            and (goats all_match (each.location distance_to {0, 0} <= 0.001)) {
        // Run number: one more than the runs already in the end-state file (its lines minus the header), or 1 if there is no file yet
        run_number <- file_exists(results_folder + "class5_end_state.csv")
            ? length(text_file(results_folder + "class5_end_state.csv").contents where (each != "")) : 1;

        // Chart 1: goats' mean total distance at every step
        string rows <- file_exists(results_folder + "class5_goat_distance.csv") ? "" : "run,step,goat_mean_total_distance\n";
        loop p over: goat_distance_series {
            rows <- rows + run_number + "," + int(p.x) + "," + p.y + "\n";
        }
        save rows to: results_folder + "class5_goat_distance.csv" format: "text" rewrite: false;

        // Chart 2: first-step distance of every cow and sheep, plus the two means shown in the chart
        rows <- file_exists(results_folder + "class5_first_step.csv") ? "" : "run,species,animal,first_step_distance\n";
        loop c over: cows {
            rows <- rows + run_number + ",cows," + c.name + "," + c.first_step_distance + "\n";
        }
        rows <- rows + run_number + ",cows,mean," + mean(cows collect each.first_step_distance) + "\n";
        loop s over: sheep {
            rows <- rows + run_number + ",sheep," + s.name + "," + s.first_step_distance + "\n";
        }
        rows <- rows + run_number + ",sheep,mean," + mean(sheep collect each.first_step_distance) + "\n";
        save rows to: results_folder + "class5_first_step.csv" format: "text" rewrite: false;

        // Chart 3: every raw cow direction change with its step, so it can be binned again
        rows <- file_exists(results_folder + "class5_cow_turns.csv") ? "" : "run,step,turn_angle\n";
        if (!empty(cow_turn_angles)) {
            loop i from: 0 to: length(cow_turn_angles) - 1 {
                rows <- rows + run_number + "," + cow_turn_steps[i] + "," + cow_turn_angles[i] + "\n";
            }
        }
        save rows to: results_folder + "class5_cow_turns.csv" format: "text" rewrite: false;

        // End state: steps done and the two monitor values, which should both be 0
        rows <- file_exists(results_folder + "class5_end_state.csv") ? "" : "run,end_step,sheep_not_at_south_edge,goats_not_at_origin\n";
        rows <- rows + run_number + "," + cycle + "," + (sheep count (world.shape.height - each.location.y > 0.001)) + ","
            + (goats count (each.location distance_to {0, 0} > 0.001)) + "\n";
        save rows to: results_folder + "class5_end_state.csv" format: "text" rewrite: false;

        results_saved <- true;
        do pause;
    }

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
        // Start at least one step (speed) from every edge, so the first step never hits the edge and is always speed long
        location <- {rnd(speed, world.shape.width - speed), rnd(speed, world.shape.height - speed)};
    }

    // Correlated random walk, up to 45 degrees either side of the heading; the first step's length is saved,
    // and each direction change (-180 to 180) is added to cow_turn_angles unless it is an edge turn-around
    reflex move {
        point previous_location <- location;
        float previous_heading <- heading;
        do wander amplitude: 90.0;
        if (cycle = 0) {
            first_step_distance <- previous_location distance_to location;
        }
        float turn <- heading - previous_heading;
        turn <- turn - 360 * floor((turn + 180) / 360);
        if (abs(turn) <= 45) {
            add turn to: cow_turn_angles;
            add cycle + 1 to: cow_turn_steps;
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
        // Monitor 1: number of sheep that have not yet reached the south (bottom) edge
        monitor "Sheep not yet at the south edge" value: sheep count (world.shape.height - each.location.y > 0.001);
        // Monitor 2: number of goats that have not yet reached the origin {0,0}
        monitor "Goats not yet at the origin" value: goats count (each.location distance_to {0, 0} > 0.001);

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

        // Goal 2: mean distance travelled by cows and sheep in the first step; x axis fixed around 1 so it shows a single tick "1"
        display first_step_chart type:2d {
            chart "Mean distance travelled in the first step" type: scatter x_range: [0.5, 1.5] x_tick_unit: 1 x_label: "Step" y_label: "Distance" {
                data "Cows mean" value: (cows none_matches (each.first_step_distance < 0)) ? {1, mean(cows collect each.first_step_distance)} : nil color: #brown marker_shape: marker_circle;
                data "Sheep mean" value: (sheep none_matches (each.first_step_distance < 0)) ? {1, mean(sheep collect each.first_step_distance)} : nil color: #black marker_shape: marker_circle;
            }
        }

        // Goal 3: distribution of all cow direction changes so far, 18 bins of 5 degrees from -45 to 45 on a numeric x axis;
        // lines are listed first so they are drawn on top of the brown bars; the 0 line reaches 15% above the highest bar
        display cow_turn_histogram type:2d {
            chart "Cows: distribution of direction changes" type: xy x_range: [-45, 45] x_tick_unit: 5 x_label: "Direction change (degrees)" y_label: "Count" {
                data "0 degrees" value: [{0.0, 0.0}, {0.0, max(world.cow_turn_outline() collect each.y) * 1.15 + 1}] style: line color: #black thickness: 2.0 marker: false;
                data "Bar edges" value: world.cow_turn_outline() style: line color: #black marker: false;
                data "Cows direction changes" value: world.cow_turn_outline() style: area color: #brown marker: false;
            }
        }
    }
}
