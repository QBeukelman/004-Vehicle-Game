//
//  VehicleActions.swift
//  Game
//
//  Created by Quentin Beukelman on 17/05/2023.
//

import Foundation

extension MapViewController {
    
    // MARK: - CONTROL: Local
    @objc func accelerateDown() {
        currentVehicle.applyEngineForce(200, forWheelAt: 0)
        currentVehicle.applyEngineForce(200, forWheelAt: 1)
        currentVehicle.applyEngineForce(50, forWheelAt: 2)
        currentVehicle.applyEngineForce(50, forWheelAt: 3)
    }
    @objc func steerLeftDown() {
        currentVehicle.setSteeringAngle(0.5, forWheelAt: 0)
        currentVehicle.setSteeringAngle(0.5, forWheelAt: 1)
    }
    @objc func steerRightDown() {
        currentVehicle.setSteeringAngle(-0.5, forWheelAt: 0)
        currentVehicle.setSteeringAngle(-0.5, forWheelAt: 1)
    }
    @objc func breakDown() {
        currentVehicle.applyEngineForce(-50, forWheelAt: 0)
        currentVehicle.applyEngineForce(-50, forWheelAt: 1)
        currentVehicle.applyEngineForce(-50, forWheelAt: 2)
        currentVehicle.applyEngineForce(-50, forWheelAt: 3)
    }
    @objc func clearSteering() {
        currentVehicle.setSteeringAngle(0, forWheelAt: 0)
        currentVehicle.setSteeringAngle(0, forWheelAt: 1)
    }
    @objc func clearAccelerate() {
        currentVehicle.applyEngineForce(0, forWheelAt: 0)
        currentVehicle.applyEngineForce(0, forWheelAt: 1)
        currentVehicle.applyEngineForce(0, forWheelAt: 2)
        currentVehicle.applyEngineForce(0, forWheelAt: 3)
    }
    @objc func clearBreak() {
        currentVehicle.applyEngineForce(0, forWheelAt: 0)
        currentVehicle.applyEngineForce(0, forWheelAt: 1)
        currentVehicle.applyEngineForce(0, forWheelAt: 2)
        currentVehicle.applyEngineForce(0, forWheelAt: 3)
    }
    @objc func resetVehiclePosition() {
        currentVehicle.chassisBody.resetTransform()
    }

    // MARK: - CONTROL: Online
    @objc func accelerateDown_opp() {
        opponentVehicle.applyEngineForce(10, forWheelAt: 0)
        opponentVehicle.applyEngineForce(10, forWheelAt: 1)
        opponentVehicle.applyEngineForce(10, forWheelAt: 2)
        opponentVehicle.applyEngineForce(10, forWheelAt: 3)
    }
    @objc func steerLeftDown_opp() {
        opponentVehicle.setSteeringAngle(0.5, forWheelAt: 0)
        opponentVehicle.setSteeringAngle(0.5, forWheelAt: 1)
    }
    @objc func steerRightDown_opp() {
        opponentVehicle.setSteeringAngle(-0.5, forWheelAt: 0)
        opponentVehicle.setSteeringAngle(-0.5, forWheelAt: 1)
    }
    @objc func breakDown_opp() {
        opponentVehicle.applyEngineForce(-10, forWheelAt: 0)
        opponentVehicle.applyEngineForce(-10, forWheelAt: 1)
        opponentVehicle.applyEngineForce(-10, forWheelAt: 2)
        opponentVehicle.applyEngineForce(-10, forWheelAt: 3)
    }
    @objc func clearSteering_opp() {
        opponentVehicle.setSteeringAngle(0, forWheelAt: 0)
        opponentVehicle.setSteeringAngle(0, forWheelAt: 1)
    }
    @objc func clearAccelerate_opp() {
        opponentVehicle.applyEngineForce(0, forWheelAt: 0)
        opponentVehicle.applyEngineForce(0, forWheelAt: 1)
        opponentVehicle.applyEngineForce(0, forWheelAt: 2)
        opponentVehicle.applyEngineForce(0, forWheelAt: 3)
    }
    @objc func clearBreak_opp() {
        opponentVehicle.applyEngineForce(0, forWheelAt: 0)
        opponentVehicle.applyEngineForce(0, forWheelAt: 1)
        opponentVehicle.applyEngineForce(0, forWheelAt: 2)
        opponentVehicle.applyEngineForce(0, forWheelAt: 3)
    }
    @objc func resetVehiclePosition_opp() {
        opponentVehicle.chassisBody.resetTransform()
    }

    
}

