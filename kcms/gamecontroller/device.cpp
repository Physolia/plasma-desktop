/*
    SPDX-FileCopyrightText: 2024 Arthur Kasimov <kodemeister@outlook.com>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "device.h"

Device::Device(int deviceIndex, QObject *parent)
    : QObject(parent)
    , m_deviceIndex(deviceIndex)
{
}

Device::~Device()
{
    close();
}

bool Device::open()
{
    if (m_joystick != nullptr) {
        return true;
    }

    m_joystick = SDL_JoystickOpen(m_deviceIndex);
    return m_joystick != nullptr;
}

void Device::close()
{
    if (m_joystick == nullptr) {
        return;
    }

    SDL_JoystickClose(m_joystick);
    m_joystick = nullptr;
}

SDL_JoystickID Device::id() const
{
    return SDL_JoystickInstanceID(m_joystick);
}

QString Device::name() const
{
    return QString::fromLocal8Bit(SDL_JoystickName(m_joystick));
}

QString Device::path() const
{
    return QString::fromLocal8Bit(SDL_JoystickPath(m_joystick));
}

bool Device::isVirtual() const
{
    return SDL_JoystickIsVirtual(m_deviceIndex);
}

int Device::buttonCount() const
{
    return SDL_JoystickNumButtons(m_joystick);
}

bool Device::buttonState(int index) const
{
    return SDL_JoystickGetButton(m_joystick, index) != 0;
}

int Device::axisCount() const
{
    return SDL_JoystickNumAxes(m_joystick);
}

int Device::axisValue(int index) const
{
    return SDL_JoystickGetAxis(m_joystick, index);
}

int Device::hatCount() const
{
    return SDL_JoystickNumHats(m_joystick);
}

QVector2D Device::hatPosition(int index) const
{
    const Uint8 hat = SDL_JoystickGetHat(m_joystick, index);
    QVector2D position;

    if ((hat & SDL_HAT_LEFT) != 0) {
        position.setX(std::numeric_limits<Sint16>::min());
    } else if ((hat & SDL_HAT_RIGHT) != 0) {
        position.setX(std::numeric_limits<Sint16>::max());
    }

    if ((hat & SDL_HAT_UP) != 0) {
        position.setY(std::numeric_limits<Sint16>::min());
    } else if ((hat & SDL_HAT_DOWN) != 0) {
        position.setY(std::numeric_limits<Sint16>::max());
    }

    return position;
}

void Device::onButtonEvent(const SDL_JoyButtonEvent &event)
{
    Q_EMIT buttonStateChanged(event.button);
}

void Device::onAxisEvent(const SDL_JoyAxisEvent &event)
{
    Q_EMIT axisValueChanged(event.axis);
}

void Device::onHatEvent(const SDL_JoyHatEvent &event)
{
    Q_EMIT hatPositionChanged(event.hat);
}

#include "moc_device.cpp"
