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
    
    // 初始化颜色（后续会在reflex中动态更新）
    rgb color <- rgb(0, int(255 * (biomass / 10.0)), 0);
    
    // 环境与规则：草地的生长行为，每次循环都会执行
    reflex grow {
        // 每次循环生物量自动增加0.1
        biomass <- biomass + 0.1;
        
        // 最高上限为10.0
        if (biomass > 10.0) {
            biomass <- 10.0;
        }        
        // 动态更新颜色：生物量数值越高，绿色通道的值越接近255，网格颜色越绿
        color <- rgb(0, int(255 * (biomass / 10.0)), 0);
    }
}

// 添加 moving 技能，使智能体能够移动
species lion skills: [moving] {
    // Random initial location
    init {
        location <- any_location_in(world);
    }
    
    // 行为：在网格内随机游走
    reflex move {
        do wander;
    }
    
    // 行为：自动捕杀距离1以内所有的斑马
    reflex hunt {
        // 找到距离自身 1 范围内的所有斑马，并让它们死亡（do die）
        ask zebra at_distance 1 {
            do die;
        }
    }
    
    aspect base {
        // 修改为半径为 3 的圆形
        draw circle(3) color: #red border: #black;
    }
}

// 添加 moving 技能，使智能体能够移动
species zebra skills: [moving] {
    // Random initial location
    init {
        location <- any_location_in(world);
    }
    
    // 行为：在网格内随机游走
    reflex move {
        do wander;
    }
    
    aspect base {
        // 修改为尺寸为 2 的灰色三角形
        draw triangle(2) color: #gray border: #black;
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