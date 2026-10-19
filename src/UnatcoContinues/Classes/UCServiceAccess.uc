// Internal legacy flag names stay stable; the physical route is behind storage.
class UCServiceAccess extends Object abstract;

static function vector Stage(int slot)
{
    switch(slot)
    {
        case 1: return vect(784,-1552,208);
        case 2: return vect(848,-1424,208);
        case 3: return vect(880,-1488,208);
    }
    return vect(784,-1488,208);
}

static function bool Inside(vector location)
{
    return location.Y>-1140 && location.Y<-700 && location.X>16 && location.X<272;
}

static function bool Outside(vector location)
{
    return location.Y<-1200;
}
