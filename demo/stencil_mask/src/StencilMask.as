/**
 * Created by Roman Lipovskiy on 17.01.2017.
 */
package
{
import com.catalystapps.gaf.data.GAFTimeline;
import com.catalystapps.gaf.display.GAFMovieClip;

    public dynamic class StencilMask extends GAFMovieClip
    {
        public function StencilMask(gafTimeline: GAFTimeline):void
        {
            super(gafTimeline);
            play(true);
        }
    }
}