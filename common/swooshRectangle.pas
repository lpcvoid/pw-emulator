unit swooshRectangle;

interface

uses windows, System.Types,System.SysUtils;

type
  TswooshSpanRectangle3D = class
    constructor Create( centerX, centerY, spanX, spanY, height: Single );
    function isPointInRect2D( x, y: Single ): boolean;
    function isPointInRect3D( x, y, height: Single ): boolean;

    //Debug and demo function
    function getDimensionString : String;

  private

    // parameter shit
    _centerX: Single;
    _centerY: Single;
    _spanX  : Single;
    _spanY  : Single;
    _height : Single;

    // calculated shit
    _calculatedRightSide: Single;
    _calculatedLeftSide : Single;
    _calculatedTop      : Single;
    _CalculatedBottom   : Single;

  end;

implementation

constructor TswooshSpanRectangle3D.Create( centerX, centerY, spanX, spanY, height: Single );
begin
  self._centerX := centerX;
  self._centerY := centerY;
  self._spanX := spanX;
  self._spanY := spanY;
  self._height := height;

  // calculate actual rectangle

  self._calculatedRightSide := centerX + Abs( spanX );
  self._calculatedLeftSide := centerX - Abs( spanX );

  self._calculatedTop := centerY + Abs( spanY );
  self._CalculatedBottom := centerY - Abs( spanY );

end;

/// <remarks>
/// Find if point is in bounding rect, disregarding height.
/// </remarks>

function TswooshSpanRectangle3D.isPointInRect2D( x, y: Single ): boolean;
begin
  Result := ( x >= self._calculatedLeftSide ) and ( x < self._calculatedRightSide ) and ( y >= self._calculatedTop ) and ( y < self._CalculatedBottom );
end;

function TswooshSpanRectangle3D.isPointInRect3D( x, y, height: Single ): boolean;
begin
  Result := self.isPointInRect2D(x,y) and (height <= self._height);
end;

function TswooshSpanRectangle3D.getDimensionString : String;
begin
  result :=
  FloatToStr(self._calculatedRightSide) + ' / ' +
  FloatToStr(self._calculatedLeftSide) + ' / ' +
  FloatToStr(self._calculatedTop) + ' / ' +
  FloatToStr(self._CalculatedBottom);
end;

end.
