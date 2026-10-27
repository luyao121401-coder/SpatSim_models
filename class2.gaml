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
    
    // 初始化颜色
    rgb color <- rgb(0, int(255 * (biomass / 10.0)), 0);
    
    // 环境与规则：草地的生长行为，每次循环都会执行
    reflex grow {
        biomass <- biomass + 0.1;
        
        if (biomass > 10.0) {
            biomass <- 10.0;
        }        
        color <- rgb(0, int(255 * (biomass / 10.0)), 0);
    }
}

// 添加 moving 技能，使智能体能够移动
species lion skills: [moving] {
    // 新增：狮子的初始能量（在2000到3500之间随机）
    int energy <- rnd(2000, 3500);
    
    init {
        location <- any_location_in(world);
    }
    
    // 行为：在网格内随机游走，并消耗能量
    reflex move {
        do wander;
        // 每次移动后能量减 1
        energy <- energy - 1;
    }
    
    // 行为：自动捕杀距离1以内所有的斑马
    reflex hunt {
        ask zebra at_distance 1 {
            do die; // 斑马死亡
            // myself 指代的是执行 ask 命令的调用者，也就是这头狮子本身
            // 每吃掉一只斑马，狮子增加 300 点能量
            myself.energy <- myself.energy + 300; 
        }
    }
    
    // 新增行为：当能量降至0或以下时，狮子死亡
    reflex starve when: energy <= 0 {
        do die;
    }
    
    aspect base {
        draw circle(3) color: #red border: #black;
    }
}

// 添加 moving 技能，使智能体能够移动
species zebra skills: [moving] {
    init {
        location <- any_location_in(world);
    }
    
    // 行为：在网格内随机游走
    reflex move {
        do wander;
    }
    
    // 行为：斑马吃草
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
    output {
        display map {
            grid grassland border: #darkgreen;
            species zebra aspect: base;
            species lion aspect: base;
        }
    }
}