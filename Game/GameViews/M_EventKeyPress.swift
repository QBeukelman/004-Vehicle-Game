//
//  EventHandling.swift
//  Game
//
//  Created by Quentin Beukelman on 17/05/2023.
//

import Foundation
import SceneKit

extension MapViewController {
    func handleKeyDownEvent(event: NSEvent) {
        switch event.characters {
        case "a":
            queue.sync {
                inputDict["a"] = true
            }
            updateVehicleInput()
            steerLeftDown()
        case "d":
            queue.sync {
                inputDict["d"] = true
            }
            updateVehicleInput()
            steerRightDown()
        case "w":
            queue.sync {
                inputDict["w"] = true
            }
            updateVehicleInput()
            accelerateDown()
        case "s":
            queue.sync {
                inputDict["s"] = true
            }
            updateVehicleInput()
            breakDown()
        case "r":
            resetVehiclePosition()
        default:
            break
        }
    }
    
    func handleKeyUpEvent(event: NSEvent) {
        switch event.characters {
        case "a":
            queue.sync {
                inputDict["a"] = false
            }
            updateVehicleInput()
            clearSteering()
        case "d":
            queue.sync {
                inputDict["d"] = false
            }
            updateVehicleInput()
            clearSteering()
        case "w":
            queue.sync {
                inputDict["w"] = false
            }
            updateVehicleInput()
            clearAccelerate()
        case "s":
            queue.sync {
                inputDict["s"] = false
            }
            updateVehicleInput()
            clearBreak()
        default:
            break
        }
    }
}
