import { Controller, Get, Post, Patch, Delete, Body, Param, UseGuards, Request } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { ListsService } from './lists.service.js';
import { CreateListDto, UpdateListDto } from './dto/list.dto.js';
import { JwtAuthGuard } from '../auth/jwt-auth.guard.js';

@ApiTags('清单')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('lists')
export class ListsController {
  constructor(private listsService: ListsService) {}

  @Get()
  @ApiOperation({ summary: '获取所有清单' })
  findAll(@Request() req: { user: { userId: string } }) {
    return this.listsService.findAll(req.user.userId);
  }

  @Post()
  @ApiOperation({ summary: '创建清单' })
  create(@Request() req: { user: { userId: string } }, @Body() dto: CreateListDto) {
    return this.listsService.create(req.user.userId, dto);
  }

  @Patch(':id')
  @ApiOperation({ summary: '更新清单' })
  update(@Request() req: { user: { userId: string } }, @Param('id') id: string, @Body() dto: UpdateListDto) {
    return this.listsService.update(req.user.userId, id, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: '删除清单' })
  remove(@Request() req: { user: { userId: string } }, @Param('id') id: string) {
    return this.listsService.remove(req.user.userId, id);
  }
}
