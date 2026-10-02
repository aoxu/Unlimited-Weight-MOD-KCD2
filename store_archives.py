"""Normalize packages to actual ZIP stored entries and verify contents."""
from pathlib import Path
import struct
import sys
import zipfile
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parent
pak = root / 'dist/UnlimitedWeight/Data/unlimitedweight.pak'
with zipfile.ZipFile(pak) as archive:
    files = [(entry.filename, archive.read(entry)) for entry in archive.infolist()]
with zipfile.ZipFile(pak, 'w', compression=zipfile.ZIP_STORED) as archive:
    for name, data in files:
        archive.writestr(name, data)
with zipfile.ZipFile(pak) as archive:
    assert archive.testzip() is None
    assert archive.namelist() == ['Libs/Tables/rpg/rpg_param__unlimitedweight.xml']
    assert all(e.compress_type == 0 and e.file_size == e.compress_size for e in archive.infolist())
    rows = ET.fromstring(archive.read(archive.namelist()[0])).findall('./rpg_params/rpg_param')
    assert {r.attrib['rpg_param_key']: r.attrib['rpg_param_value'] for r in rows} == {
        'BaseInventoryCapacity': '999999', 'MaxBaseInventoryCapacity': '999999'
    }
assert struct.unpack_from('<H', pak.read_bytes(), 8)[0] == 0
package = Path(sys.argv[1])
with zipfile.ZipFile(package, 'w', compression=zipfile.ZIP_STORED) as archive:
    for relative in ('mod.manifest', 'Data/unlimitedweight.pak'):
        archive.write(root / 'dist/UnlimitedWeight' / relative, 'UnlimitedWeight/' + relative)
with zipfile.ZipFile(package) as archive:
    assert archive.testzip() is None
print('Verified actual ZIP_STORED method 0, CRC and both capacity parameters.')
